from fastapi import APIRouter, Depends
from app.schemas.user import UserResponse
from app.utils.auth import get_current_user

router = APIRouter(tags=["Authentication"])

@router.post("/firebase-login", response_model=UserResponse)
async def firebase_login(user=Depends(get_current_user)):
    return user