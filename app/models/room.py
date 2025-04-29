from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database.database import Base
import datetime

class Room(Base):
    __tablename__ = "rooms"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    game = Column(String(255), nullable=False)
    password = Column(String(255), nullable=True)
    max_players = Column(Integer, nullable=False)
    host_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    host = relationship("User", backref="hosted_rooms")
    players = relationship("RoomPlayer", back_populates="room", cascade="all, delete-orphan")