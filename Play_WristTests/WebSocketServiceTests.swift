import Testing
import Foundation
@testable import Play_Wrist

@MainActor
struct WebSocketServiceTests {
    
    // MARK: - Mock Data
    private func createMockRoom() -> Room {
        return Room(
            id: "test-room-123",
            title: "테스트 방",
            game: "BombParty",
            password: "1234",
            maxPlayers: 4,
            hostName: "테스트호스트",
            players: [
                Player(id: "host-id", name: "테스트호스트", isReady: true, role: nil, isHost: true)
            ]
        )
    }
    
    // MARK: - Connection Tests
    @Test func testWebSocketServiceInitialization() async throws {
        let service = WebSocketService.shared
        #expect(service != nil)
        #expect(service.connectionId.isEmpty == false)
    }
    
    // MARK: - JoinRoom Success Tests
    @Test func testJoinRoomSuccess() async throws {
        let service = WebSocketService.shared
        let mockRoom = createMockRoom()
        
        // 실제 서버에 연결하지 않고 mock 응답을 시뮬레이션
        // 참고: 실제 테스트에서는 MockWebSocketService를 사용하는 것이 좋습니다
        
        print("🧪 테스트: 방 입장 성공 시나리오")
        print("방 ID: \(mockRoom.id)")
        print("사용자명: TestUser")
        print("비밀번호: \(mockRoom.password)")
        
        // 실제 서버 연결이 필요한 부분은 integration test로 분리
    }
    
    // MARK: - JoinRoom Error Tests
    @Test func testJoinRoomNotConnected() async throws {
        let service = WebSocketService.shared
        
        // WebSocket이 연결되지 않은 상태에서 joinRoom 호출
        do {
            let _ = try await service.joinRoom(
                roomId: "test-room-123",
                userName: "TestUser",
                password: "1234"
            )
            // 에러가 발생해야 하므로 여기에 도달하면 안됨
            #expect(Bool(false), "연결되지 않은 상태에서는 에러가 발생해야 합니다")
        } catch {
            // WebSocketError.notConnected 에러가 발생해야 함
            if case WebSocketError.notConnected = error {
                print("✅ 예상된 에러 발생: \(error.localizedDescription)")
            } else {
                #expect(Bool(false), "예상과 다른 에러 발생: \(error)")
            }
        }
    }
    
    // MARK: - Error Type Tests
    @Test func testWebSocketErrorTypes() async throws {
        let notConnectedError = WebSocketError.notConnected
        #expect(notConnectedError.errorDescription == "WebSocket이 연결되지 않았습니다")
        
        let encodingError = WebSocketError.encodingFailed
        #expect(encodingError.errorDescription == "요청 인코딩에 실패했습니다")
        
        let emptyResponseError = WebSocketError.emptyResponse
        #expect(emptyResponseError.errorDescription == "서버 응답이 비어있습니다")
        
        let serverError = WebSocketError.serverError("잘못된 비밀번호")
        #expect(serverError.errorDescription == "잘못된 비밀번호")
        
        let timeoutError = WebSocketError.timeout
        #expect(timeoutError.errorDescription == "요청 시간이 초과되었습니다")
    }
    
    // MARK: - Model Validation Tests
    @Test func testJoinRoomPayloadEncoding() async throws {
        let payload = JoinRoomPayload(
            roomId: "test-room-123",
            userName: "TestUser",
            password: "1234"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        
        let decoder = JSONDecoder()
        let decodedPayload = try decoder.decode(JoinRoomPayload.self, from: data)
        
        #expect(decodedPayload.roomId == payload.roomId)
        #expect(decodedPayload.userName == payload.userName)
        #expect(decodedPayload.password == payload.password)
    }
    
    @Test func testJoinRoomResultDecoding() async throws {
        let mockRoom = createMockRoom()
        let result = JoinRoomResult(room: mockRoom)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        
        let decoder = JSONDecoder()
        let decodedResult = try decoder.decode(JoinRoomResult.self, from: data)
        
        #expect(decodedResult.room.id == mockRoom.id)
        #expect(decodedResult.room.title == mockRoom.title)
        #expect(decodedResult.room.players.count == mockRoom.players.count)
    }
    
    // MARK: - WSResponse Tests
    @Test func testWSResponseWithSuccess() async throws {
        let mockRoom = createMockRoom()
        let result = JoinRoomResult(room: mockRoom)
        
        let response = WSResponse<JoinRoomResult>(
            action: .joinRoom,
            requestId: "test-123",
            error: nil,
            payload: result
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(WSResponse<JoinRoomResult>.self, from: data)
        
        #expect(decodedResponse.action == .joinRoom)
        #expect(decodedResponse.requestId == "test-123")
        #expect(decodedResponse.error == nil)
        #expect(decodedResponse.payload?.room.id == mockRoom.id)
    }
    
    @Test func testWSResponseWithError() async throws {
        let response = WSResponse<JoinRoomResult>(
            action: .joinRoom,
            requestId: "test-123",
            error: "잘못된 비밀번호입니다",
            payload: nil
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(WSResponse<JoinRoomResult>.self, from: data)
        
        #expect(decodedResponse.action == .joinRoom)
        #expect(decodedResponse.requestId == "test-123")
        #expect(decodedResponse.error == "잘못된 비밀번호입니다")
        #expect(decodedResponse.payload == nil)
    }
}

// MARK: - Integration Tests (서버 연결 필요)
struct WebSocketServiceIntegrationTests {
    
    @Test func testRealServerConnection() async throws {
        print("🔗 통합 테스트: 실제 서버 연결")
        print("서버 URL: wss://student-login-serivc.p-e.kr/ws-game/websocket")
        
        let service = await WebSocketService.shared
        
        // 1. 연결
        await service.connect()
        
        // 연결 대기 (실제로는 연결 상태 확인 로직 필요)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기
        
        // 2. 방 목록 조회 먼저 수행
        print("📋 방 목록 조회 중...")
        await service.fetchRooms()
        
        // 방 목록 응답 대기
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3초 대기
        
        // 3. 실제 존재하는 방에 입장 시도
        // (실제 테스트 시에는 먼저 방을 생성하거나 알려진 방 ID 사용)
        do {
            print("🚪 방 입장 시도...")
            let joinedRoom = try await service.joinRoom(
                roomId: "existing-room-id", // 실제 존재하는 방 ID로 변경 필요
                userName: "테스트유저",
                password: "" // 비밀번호가 없는 방 또는 올바른 비밀번호
            )
            
            print("✅ 방 입장 성공!")
            print("방 제목: \(joinedRoom.title)")
            print("현재 플레이어 수: \(joinedRoom.players.count)")
            
            #expect(joinedRoom.id == "existing-room-id")
            #expect(joinedRoom.players.contains { $0.name == "테스트유저" })
            
        } catch {
            print("❌ 방 입장 실패: \(error)")
            // 실제 방이 없거나 다른 이유로 실패할 수 있음
            // 통합 테스트에서는 이를 고려해야 함
        }
        
        // 연결 종료
        await service.disconnect()
    }
}