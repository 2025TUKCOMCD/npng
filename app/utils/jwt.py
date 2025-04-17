from datetime import datetime, timedelta
from jose import jwt
from app.config import settings

def create_access_token(user_id: int):
    expires = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {
        "sub": str(user_id),
        "exp": expires,
        "type": "access"
    }
    return jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm
    )