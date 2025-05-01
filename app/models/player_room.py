from app.database.database import Base
from sqlalchemy import Column, Integer, Boolean, ForeignKey
from sqlalchemy.orm import relationship

class PlayerRoomAssociation(Base):
    __tablename__ = "player_room_association"

    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    room_id = Column(Integer, ForeignKey("rooms.id"), primary_key=True)
    is_ready = Column(Boolean, default=False)
    is_host = Column(Boolean, default=False)

    user = relationship("User", back_populates="rooms")
    room = relationship("Room", back_populates="players")