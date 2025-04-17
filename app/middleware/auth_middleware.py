from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from firebase_admin import auth
from app.database.database import get_db
from app.crud.user import get_user_by_firebase_uid  # create_firebase_user 제거

class FirebaseAuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        auth_header = request.headers.get("Authorization")

        if not auth_header or not auth_header.startswith("Bearer "):
            return await call_next(request)

        id_token = auth_header.split("Bearer ")[-1].strip()

        try:
            # Firebase 토큰 검증
            decoded_token = auth.verify_id_token(id_token)
            firebase_uid = decoded_token["uid"]

            # DB에서 사용자 조회만 수행
            db = next(get_db())
            user = get_user_by_firebase_uid(db, firebase_uid)
            
            if not user:
                raise HTTPException(status_code=404, detail="User not found")

            request.state.user = user

        except auth.InvalidIdTokenError:
            raise HTTPException(status_code=401, detail="Invalid Firebase token")
        except auth.ExpiredIdTokenError:
            raise HTTPException(status_code=401, detail="Expired Firebase token")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

        return await call_next(request)