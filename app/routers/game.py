from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Dict
from sqlalchemy.orm import Session
import random
import time

from app.database.database import get_db
from app.utils.auth import get_current_user
from app.models import Room, PlayerRoomAssociation, User

router = APIRouter(tags=["Game Management"])

# --- 요청 모델들 ---
class BombPassRequest(BaseModel):
    from_player_id: int  # user_id
    to_player_id: int    # user_id

class GameResultCheckRequest(BaseModel):
    holder_id: int  # 현재 폭탄 소지자 user_id

class RoleAssignmentResponse(BaseModel):
    roles: Dict[int, str]  # { user_id: 역할명 }
    location: str


# 스파이폴 장소 및 역할 예시
locations = {
    "병원": ["의사", "간호사", "환자", "응급구조사", "방문객"],
    "학교": ["선생님", "학생", "청소부", "급식조리사", "교장"],
    "공항": ["조종사", "승무원", "여객", "공항직원", "세관요원"]
}


# 3. 폭탄 랜덤 배정
@router.post("/rooms/{room_id}/assign-bomb")
def assign_bomb(room_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    players = db.query(PlayerRoomAssociation).filter(PlayerRoomAssociation.room_id == room_id).all()
    if not players:
        raise HTTPException(status_code=400, detail="No players in room")

    chosen_player = random.choice(players)
    # DB에 폭탄 소지자 정보 저장을 위한 컬럼이 없으면, 따로 구현 필요
    # 여기서는 임시로 room에 임시 저장 (비영속적)
    room.bomb_holder_id = chosen_player.user_id  
    db.commit()

    return {"bomb_holder_id": chosen_player.user_id}


# 4. 폭탄 넘기기
@router.post("/rooms/{room_id}/pass-bomb")
def pass_bomb(room_id: int, req: BombPassRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    # 방에 저장된 bomb_holder_id가 없으면 400
    if not hasattr(room, "bomb_holder_id") or room.bomb_holder_id != req.from_player_id:
        raise HTTPException(status_code=400, detail="You don't have the bomb")

    # to_player가 방 멤버인지 확인
    to_player = db.query(PlayerRoomAssociation).filter(
        PlayerRoomAssociation.room_id == room_id,
        PlayerRoomAssociation.user_id == req.to_player_id
    ).first()
    if not to_player:
        raise HTTPException(status_code=400, detail="Invalid target player")

    # 폭탄 소지자 변경
    room.bomb_holder_id = req.to_player_id
    db.commit()

    return {"new_holder_id": req.to_player_id}


# 5. 게임 결과 체크 (폭탄 터졌는지 판단)
@router.post("/rooms/{room_id}/game-result")
def check_game_result(room_id: int, req: GameResultCheckRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    # 폭탄 소지자 정보 확인 (여기선 req로 받음)
    loser_id = req.holder_id
    players = db.query(PlayerRoomAssociation).filter(PlayerRoomAssociation.room_id == room_id).all()

    if not any(p.user_id == loser_id for p in players):
        raise HTTPException(status_code=400, detail="Invalid bomb holder")

    winners = [p.user_id for p in players if p.user_id != loser_id]

    return {"loser_id": loser_id, "winner_ids": winners}


# 6. 역할 및 장소 랜덤 배정 (SpyFall)
@router.get("/rooms/{room_id}/assign-roles", response_model=RoleAssignmentResponse)
def assign_roles(room_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    players = db.query(PlayerRoomAssociation).filter(PlayerRoomAssociation.room_id == room_id).all()
    if not players:
        raise HTTPException(status_code=400, detail="No players in room")

    location, roles = random.choice(list(locations.items()))

    # 플레이어 수 > 역할 수면 역할 수만큼 자르기
    players = players[:len(roles)]

    spy = random.choice(players)

    assignments = {}
    for player in players:
        if player.user_id == spy.user_id:
            assignments[player.user_id] = "SPY"
        else:
            assignments[player.user_id] = random.choice(roles)

    return RoleAssignmentResponse(roles=assignments, location=location)


# 7. 스파이폴 타이머 시작 (5분 고정)
@router.post("/rooms/{room_id}/start-spyfall-timer")
def start_spyfall(room_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    # 실제 타임스탬프 저장 (DB에 필드 없으면 별도 관리 필요)
    room.start_time = time.time()
    db.commit()

    return {"message": "SpyFall timer started (5분 고정)"}

@router.post("/rooms/{room_id}/start")
def start_game(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        print(f"✅ [start_game] called - room_id: {room_id}")
        print(f"🔐 current_user.id: {current_user.id}")

        room = db.query(Room).filter(Room.id == room_id).first()
        if not room:
            raise HTTPException(status_code=404, detail="Room not found")
        
        print(f"🏠 room.host_id: {room.host_id}")

        if room.host_id != current_user.id:
            raise HTTPException(status_code=403, detail="Only the host can start the game")

        if room.game_started:
            raise HTTPException(status_code=400, detail="Game already started")
        
        players = db.query(PlayerRoomAssociation).filter(PlayerRoomAssociation.room_id == room_id).all()
        if not players:
            raise HTTPException(status_code=400, detail="No players in room")

        print("👥 Players in room:")
        for p in players:
            print(f"   - user_id: {p.user_id}, is_ready: {getattr(p, 'is_ready', '❌ 없음')}")

        if any(not getattr(p, "is_ready", False) for p in players):
            raise HTTPException(status_code=400, detail="Not all players are ready")
        
        room.game_started = True
        db.commit()

        player_list = [{
            "user_id": p.user_id,
            "is_ready": getattr(p, "is_ready", False)
        } for p in players]

        return {
            "message": "Game started",
            "players": player_list,
        }

    except Exception as e:
        print(f"❌ [start_game] Exception: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
