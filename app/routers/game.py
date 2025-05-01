from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.models import Room, PlayerRoomAssociation, User
from app.utils.auth import get_current_user

router = APIRouter(tags=["Game Management"])

class GameStartRequest(BaseModel):
    bomb_holder: str

@router.post("/rooms/{room_id}/start")
async def start_game(
    room_id: int,
    request: GameStartRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 방장 확인
    room = db.query(Room).get(room_id)
    if not room or room.host_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only host can start the game")

    # 플레이어 셔플 및 폭탄 소지자 할당
    players = db.query(PlayerRoomAssociation).filter(
        PlayerRoomAssociation.room_id == room_id
    ).all()

    import random
    random.shuffle(players)
    
    for idx, player in enumerate(players):
        player.player_number = f"Player{idx+1}"
        player.has_bomb = (player.user.full_name == request.bomb_holder)
    
    db.commit()
    
    return {"message": "Game started", "players": [
        {
            "player_number": p.player_number,
            "has_bomb": p.has_bomb,
            "user_name": p.user.full_name
        } for p in players
    ]}