from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from firebase_admin import auth as firebase_auth
from sqlalchemy.orm import Session
from typing import Optional
from app.utils.connection_manager import ConnectionManager
from app.database.database import get_db
from app.crud.user import get_user_by_firebase_uid

router = APIRouter(prefix="/ws", tags=["WebSocket"])
manager = ConnectionManager()

# ✅ 단일 WebSocket 엔드포인트로 통합 및 중복 제거
@router.websocket("/rooms/{room_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    room_id: int,
    token: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    # 1. 인증 처리
    user = None
    if token:
        try:
            decoded = firebase_auth.verify_id_token(token)
            user = get_user_by_firebase_uid(db, decoded["uid"])
            if not user:
                await websocket.close(code=1008)
                return
        except Exception as e:
            await websocket.close(code=1008)
            return

    # 2. WebSocket 연결 수립
    await websocket.accept()
    
    # 3. 연결 관리자에 등록
    await manager.connect(room_id, websocket)
    
    # 4. 입장 알림 전송
    await manager.broadcast(
        room_id,
        {
            "event": "system",
            "type": "join",
            "user_id": user.id if user else "anonymous",
            "message": f"User {user.id if user else 'anonymous'} joined"
        }
    )

    try:
        while True:
            # 5. 메시지 수신 및 처리
            data = await websocket.receive_json()
            
            # 6. 메시지 유효성 검증
            if "event" not in data:
                continue
                
            # 7. 이벤트 브로드캐스팅
            await manager.broadcast(
                room_id,
                {
                    "event": data["event"],
                    "user_id": user.id if user else "anonymous",
                    "payload": data.get("payload")
                }
            )
            
    except WebSocketDisconnect:
        # 8. 연결 종료 처리
        manager.disconnect(room_id, websocket)
        await manager.broadcast(
            room_id,
            {
                "event": "system",
                "type": "leave",
                "user_id": user.id if user else "anonymous",
                "message": f"User {user.id if user else 'anonymous'} left"
            }
        )
