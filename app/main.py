from fastapi import FastAPI
from app.routers import auth, user
from app.database.database import engine
from app.models.user import User
from dotenv import load_dotenv
from app.middleware.auth_middleware import FirebaseAuthMiddleware

load_dotenv()

# 데이터베이스 테이블 생성
User.metadata.create_all(bind=engine)

app = FastAPI(title="Bomb Game API", version="1.0.0")

# Firebase 인증 미들웨어 추가
app.add_middleware(FirebaseAuthMiddleware)

app.include_router(auth.router)
app.include_router(user.router)

@app.get("/health")
def health_check():
    return {"status": "OK"}