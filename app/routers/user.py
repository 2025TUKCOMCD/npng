from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.schemas.user import UserResponse, UserUpdateRequest
from app.utils.auth import get_current_user
from app.database.database import get_db
from app.crud.user import update_user, get_user_by_firebase_uid
from app.models.user import User

router = APIRouter(tags=["Users"])

# 현재 사용자 정보 조회
@router.get("/users/me", response_model=UserResponse)
async def get_current_user_info(user: User = Depends(get_current_user)):
    return user

# 사용자 정보 수정 (PATCH)
@router.patch("/users/me", response_model=UserResponse)
async def update_user_info(
    update_data: UserUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        updated_user = update_user(db, current_user, update_data.dict(exclude_unset=True))
        return updated_user
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=str(e))