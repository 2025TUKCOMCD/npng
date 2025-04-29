from typing import Dict, List
from fastapi import WebSocket
from collections import defaultdict

class ConnectionManager:
    """
    방(room_id)별 WebSocket 연결을 관리하는 싱글톤 매니저
    """
    def __init__(self):
        # key: room_id, value: 연결된 WebSocket 리스트
        self.active_connections: Dict[int, List[WebSocket]] = defaultdict(list)

    async def connect(self, room_id: int, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[room_id].append(websocket)

    def disconnect(self, room_id: int, websocket: WebSocket):
        self.active_connections[room_id].remove(websocket)

    async def broadcast(self, room_id: int, message: dict):
        """
        해당 room_id에 연결된 모든 클라이언트에 JSON 메시지를 전송
        """
        for ws in list(self.active_connections[room_id]):
            try:
                await ws.send_json(message)
            except Exception:
                # 연결 끊긴 경우 제거
                self.disconnect(room_id, ws)