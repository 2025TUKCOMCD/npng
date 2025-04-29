from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class RoomCreateRequest(BaseModel):
    title: str = Field(..., example="재밌는 방")
    game: str = Field(..., example="Bomb Game")
    password: Optional[str] = Field(None, example="1234")
    max_players: int = Field(..., example=4)

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

class JoinRoomRequest(BaseModel):
    password: Optional[str] = Field(None, example="1234")

class ReadyRequest(BaseModel):
    is_ready: bool = Field(..., example=True)
