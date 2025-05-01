from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean
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
    
    players = relationship("PlayerRoomAssociation", back_populates="room")