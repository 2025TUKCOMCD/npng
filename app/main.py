from fastapi import FastAPI
from app.routers import auth, user, room, game, ws
from app.database.database import engine
from app.models.user import User
from dotenv import load_dotenv
from app.middleware.auth_middleware import FirebaseAuthMiddleware
from fastapi.middleware.cors import CORSMiddleware
from app.database.database import Base
import app
Base.metadata.create_all(bind=engine)


load_dotenv(dotenv_path=".env")

app = FastAPI(title="Bomb Game API", version="1.0.0")

# CORS 설정 추가
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Firebase 인증 미들웨어 추가
app.add_middleware(FirebaseAuthMiddleware)

app.include_router(auth.router)
app.include_router(user.router)
app.include_router(room.router, prefix="/api")  
app.include_router(game.router, prefix="/api")  
app.include_router(ws.router, prefix="/api")


@app.get("/health")
def health_check():
    return {"status": "OK"}

@app.get("/")
def root():
    return {"message": "Hello from Bomb Game API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",  # 모든 네트워크 인터페이스 허용
        port=8000,
        reload=True
    )
