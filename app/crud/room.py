from sqlalchemy.orm import Session
from app.models.room import Room
from app.models.room_player import RoomPlayer
from app.models.user import User
from app.schemas.room import RoomCreateRequest
from fastapi import HTTPException


def create_room(db: Session, host: User, room_data: RoomCreateRequest) -> Room:
    room = Room(
        title=room_data.title,
        game=room_data.game,
        password=room_data.password,
        max_players=room_data.max_players,
        host_id=host.id
    )
    db.add(room)
    db.commit()
    db.refresh(room)
    # Add host as first player
    join_room(db, room, host)
    return room


def get_rooms(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Room).offset(skip).limit(limit).all()


def get_room(db: Session, room_id: int) -> Room:
    return db.query(Room).filter(Room.id == room_id).first()


def join_room(db: Session, room: Room, user: User):
    if len(room.players) >= room.max_players:
        raise HTTPException(status_code=400, detail="Room is full")
    existing = db.query(RoomPlayer).filter(
        RoomPlayer.room_id == room.id,
        RoomPlayer.user_id == user.id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Already joined")
    player = RoomPlayer(room_id=room.id, user_id=user.id)
    db.add(player)
    db.commit()
    db.refresh(player)
    return player


def set_player_ready(db: Session, room_id: int, user: User, is_ready: bool) -> RoomPlayer:
    player = db.query(RoomPlayer).filter(
        RoomPlayer.room_id == room_id,
        RoomPlayer.user_id == user.id
    ).first()
    if not player:
        raise HTTPException(status_code=404, detail="Player not in room")
    player.is_ready = is_ready
    db.commit()
    db.refresh(player)
    return player


def get_room_player_status(db: Session, room_id: int):
    return db.query(RoomPlayer).filter(RoomPlayer.room_id == room_id).all()