from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from app.schemas.room import (
    RoomCreateRequest, RoomResponse,
    RoomDetailResponse, JoinRoomRequest,
    PlayerInfo, ReadyRequest
)
from app.crud.room import (
    create_room, get_rooms, get_room,
    join_room, set_player_ready, get_room_player_status
)
from app.utils.auth import get_current_user
from app.database.database import get_db
from app.models.user import User

router = APIRouter(prefix="/rooms", tags=["Rooms"])

@router.post("/", response_model=RoomResponse)
async def api_create_room(
    req: RoomCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return create_room(db, current_user, req)

@router.get("/", response_model=List[RoomResponse])
async def api_list_rooms(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    return get_rooms(db, skip, limit)

@router.get("/{room_id}", response_model=RoomDetailResponse)
async def api_get_room(
    room_id: int,
    db: Session = Depends(get_db)
):
    room = get_room(db, room_id)
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    players = [PlayerInfo.from_orm(rp.user) for rp in room.players]
    # but PlayerInfo needs is_ready
    players = [PlayerInfo(id=rp.user.id, email=rp.user.email, full_name=rp.user.full_name, is_ready=rp.is_ready) for rp in room.players]
    return RoomDetailResponse(
        **RoomResponse.from_orm(room).dict(),
        players=players
    )

@router.post("/{room_id}/join", response_model=RoomDetailResponse)
async def api_join_room(
    room_id: int,
    req: JoinRoomRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    room = get_room(db, room_id)
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room.password and room.password != req.password:
        raise HTTPException(status_code=403, detail="Incorrect password")
    join_room(db, room, current_user)
    players = [PlayerInfo(id=rp.user.id, email=rp.user.email, full_name=rp.user.full_name, is_ready=rp.is_ready) for rp in room.players]
    return RoomDetailResponse(
        **RoomResponse.from_orm(room).dict(),
        players=players
    )

@router.patch("/{room_id}/ready", response_model=PlayerInfo)
async def api_set_ready(
    room_id: int,
    req: ReadyRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    player = set_player_ready(db, room_id, current_user, req.is_ready)
    return PlayerInfo(
        id=player.user.id,
        email=player.user.email,
        full_name=player.user.full_name,
        is_ready=player.is_ready
    )

@router.get("/{room_id}/ready-status", response_model=List[PlayerInfo])
async def api_ready_status(
    room_id: int,
    db: Session = Depends(get_db)
):
    statuses = get_room_player_status(db, room_id)
    return [PlayerInfo(
        id=rp.user.id,
        email=rp.user.email,
        full_name=rp.user.full_name,
        is_ready=rp.is_ready
    ) for rp in statuses]