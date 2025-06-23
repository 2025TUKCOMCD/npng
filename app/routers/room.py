from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from typing import List
from app.database.database import get_db
from app.schemas.room import RoomCreateRequest, RoomJoinRequest, PlayerReadyRequest
from app.utils.auth import get_current_user
from app.models import User, Room, PlayerRoomAssociation
from app.database.database import get_db
from app.schemas.room import RoomResponse
from app.models.room import Room

router = APIRouter(tags=["Rooms"])

# 방 생성 엔드포인트 수정
@router.post("/rooms")
def create_room(
    request: RoomCreateRequest = Body(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        new_room = Room(
            title=request.title,
            game_type=request.game,
            password=request.password,
            max_players=request.maxPlayers,
            host_id=current_user.id  # Firebase UID 기반 사용자 ID 사용
        )
        db.add(new_room)
        db.commit()
        db.refresh(new_room)
        
        # 방 생성자 자동 참여
        association = PlayerRoomAssociation(
            user_id=current_user.id,
            room_id=new_room.id,
            is_host=True,
            is_ready=False
        )
        db.add(association)
        db.commit()
        
        return {
            "roomID": new_room.id,
            "title": new_room.title,
            "hostName": current_user.full_name
        }
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

# 방 참여 엔드포인트 수정
@router.post("/rooms/{roomID}/join")
def join_room(
    roomID: int,
    request: RoomJoinRequest = Body(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    room = db.query(Room).filter(Room.id == roomID).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    # 비밀번호 검증
    if room.password and room.password != request.inputPassword:
        raise HTTPException(status_code=403, detail="Incorrect password")
    
    # 중복 참여 확인
    existing = db.query(PlayerRoomAssociation).filter(
        PlayerRoomAssociation.user_id == current_user.id,
        PlayerRoomAssociation.room_id == roomID
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Already joined")
    
    # 방 인원 확인
    current_players = db.query(PlayerRoomAssociation).filter(
        PlayerRoomAssociation.room_id == roomID
    ).count()
    if current_players >= room.max_players:
        raise HTTPException(status_code=400, detail="Room is full")
    
    # 방 참여
    association = PlayerRoomAssociation(
        user_id=current_user.id,
        room_id=roomID,
        is_host=False,
        is_ready=False
    )
    db.add(association)
    db.commit()
    
    return {
        "status": "success",
        "roomID": roomID,
        "userName": current_user.full_name
    }

# 준비 상태 업데이트 엔드포인트 추가
@router.post("/rooms/{roomID}/ready")
def update_ready_status(
    roomID: int,
    request: PlayerReadyRequest = Body(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 방 존재 여부 확인
    room = db.query(Room).filter(Room.id == roomID).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    # 플레이어 상태 업데이트
    association = db.query(PlayerRoomAssociation).filter(
        PlayerRoomAssociation.user_id == current_user.id,
        PlayerRoomAssociation.room_id == roomID
    ).first()
    
    if not association:
        raise HTTPException(status_code=403, detail="Not a room member")
    
    association.is_ready = (request.status == "Ready")
    db.commit()
    
    return {
        "status": "success",
        "roomID": roomID,
        "userName": current_user.full_name,
        "newStatus": request.status
    }

@router.get("/rooms", response_model=List[RoomResponse])
def list_rooms(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    rooms = db.query(Room).offset(skip).limit(limit).all()
    return rooms

