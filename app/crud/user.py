from sqlalchemy.orm import Session
from app.models.user import User

def get_user_by_firebase_uid(db: Session, firebase_uid: str):
    return db.query(User).filter(User.firebase_uid == firebase_uid).first()

def update_user(db: Session, user: User, update_data: dict):
    for key, value in update_data.items():
        setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user