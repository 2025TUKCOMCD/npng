from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Float
from sqlalchemy.orm import relationship
from app.database.database import Base
import datetime

class Room(Base):
    __tablename__ = "rooms"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(100))
    game_type = Column(String(50))
    password = Column(String(100))
    max_players = Column(Integer)
    is_active = Column(Boolean, default=True)
    host_id = Column(Integer, ForeignKey("users.id"))

    bomb_holder_id = Column(Integer, nullable=True)   # 폭탄 보유자 user_id 저장용
    start_time = Column(Float, nullable=True)          # 타이머 시작 시간 저장 (timestamp)

    players = relationship("PlayerRoomAssociation", back_populates="room")