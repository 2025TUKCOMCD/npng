from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from firebase_admin import auth as firebase_auth
from sqlalchemy.orm import Session
from app.utils.connection_manager import ConnectionManager
from app.database.database import get_db
from app.crud.user import get_user_by_firebase_uid

router = APIRouter(prefix="/ws", tags=["WebSocket"])
manager = ConnectionManager()

@router.websocket("/rooms/{room_id}")
async def websocket_room(
    websocket: WebSocket,
    room_id: int,
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    # 1) (선택) Firebase 토큰 검증
    user_id = None
    if token:
        decoded = firebase_auth.verify_id_token(token)
        user = get_user_by_firebase_uid(db, decoded["uid"])
        if not user:
            # 인증 실패 시 연결 종료
            await websocket.close(code=1008)
            return
        user_id = user.id

    # 2) 클라이언트 연결
    await manager.connect(room_id, websocket)
    # 접속 알림
    await manager.broadcast(room_id, {"event": "join", "user_id": user_id})

    try:
        while True:
            data = await websocket.receive_json()
            # 메시지 수신 → 전체 브로드캐스트
            await manager.broadcast(room_id, {
                "event": "message",
                "user_id": user_id,
                "payload": data
            })
    except WebSocketDisconnect:
        # 연결 해제 처리
        manager.disconnect(room_id, websocket)
        await manager.broadcast(room_id, {"event": "leave", "user_id": user_id})