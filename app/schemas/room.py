from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class RoomResponse(BaseModel):
    id: int
    title: str
    game: str
    password: Optional[str]
    max_players: int
    host_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class PlayerInfo(BaseModel):
    id: int
    email: Optional[str]
    full_name: Optional[str]
    is_ready: bool

    class Config:
        from_attributes = True

class RoomDetailResponse(RoomResponse):
    players: List[PlayerInfo]


    # 방 생성 요청 스키마 추가
class RoomCreateRequest(BaseModel):
    room_id: int
    action: str
    title: str
    game: str  # "bomb_party" or "mafia_game"
    password: Optional[str] = None
    maxPlayers: int
    hostName: str  # 프론트에서 전달받지만 실제 사용은 안함

# 방 참여 요청 스키마 추가
class RoomJoinRequest(BaseModel):
    action: str
    userName: str  # 실제 사용은 Firebase UID 기반
    inputPassword: Optional[str] = None

# 준비 상태 스키마 추가
class PlayerReadyRequest(BaseModel):
    event: str
    roomID: int
    userName: str  # 실제 사용은 Firebase UID 기반
    status: str  # "Ready" or "Normal"
