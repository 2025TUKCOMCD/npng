from app.database.database import Base  # ✅ 명시적 임포트
from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.orm import relationship

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    apple_id = Column(String(255), unique=True, index=True)
    email = Column(String(255), unique=True, index=True)
    full_name = Column(String(255))
    is_active = Column(Boolean, default=True)
    firebase_uid = Column(String(255), unique=True)  # Firebase 연동용

    rooms = relationship("PlayerRoomAssociation", back_populates="user")