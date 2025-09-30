import XCTest
import Foundation
@testable import Play_Wrist

@MainActor
final class WebSocketServiceXCTests: XCTestCase {
    
    var webSocketService: WebSocketService!
    
    override func setUpWithError() throws {
        super.setUp()
        webSocketService = WebSocketService.shared
    }
    
    override func tearDownWithError() throws {
        webSocketService.disconnect()
        webSocketService = nil
        super.tearDown()
    }
    
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
    
    // MARK: - Initialization Tests
    func testWebSocketServiceSingleton() {
        XCTAssertNotNil(webSocketService)
        XCTAssertFalse(webSocketService.connectionId.isEmpty)
        
        let anotherInstance = WebSocketService.shared
        XCTAssertTrue(webSocketService === anotherInstance, "WebSocketService should be singleton")
    }
    
    // MARK: - Error Handling Tests
    func testJoinRoomWhenNotConnected() async {
        // Given: WebSocket이 연결되지 않은 상태
        
        // When: joinRoom 호출
        do {
            let _ = try await webSocketService.joinRoom(
                roomId: "test-room-123",
                userName: "TestUser", 
                password: "1234"
            )
            XCTFail("연결되지 않은 상태에서는 에러가 발생해야 합니다")
        } catch {
            // Then: WebSocketError.notConnected 에러가 발생해야 함
            if case WebSocketError.notConnected = error {
                XCTAssertEqual(error.localizedDescription, "WebSocket이 연결되지 않았습니다")
            } else {
                XCTFail("예상과 다른 에러 발생: \(error)")
            }
        }
    }
    
    func testWebSocketErrorLocalizedDescriptions() {
        XCTAssertEqual(
            WebSocketError.notConnected.localizedDescription,
            "WebSocket이 연결되지 않았습니다"
        )
        
        XCTAssertEqual(
            WebSocketError.encodingFailed.localizedDescription, 
            "요청 인코딩에 실패했습니다"
        )
        
        XCTAssertEqual(
            WebSocketError.emptyResponse.localizedDescription,
            "서버 응답이 비어있습니다"
        )
        
        XCTAssertEqual(
            WebSocketError.serverError("Custom error").localizedDescription,
            "Custom error"
        )
        
        XCTAssertEqual(
            WebSocketError.timeout.localizedDescription,
            "요청 시간이 초과되었습니다"
        )
    }
    
    // MARK: - Model Validation Tests
    func testJoinRoomPayloadSerialization() throws {
        // Given
        let payload = JoinRoomPayload(
            roomId: "test-room-123",
            userName: "TestUser",
            password: "1234"
        )
        
        // When: Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        
        // Then: Decode should work
        let decoder = JSONDecoder()
        let decodedPayload = try decoder.decode(JoinRoomPayload.self, from: data)
        
        XCTAssertEqual(decodedPayload.roomId, payload.roomId)
        XCTAssertEqual(decodedPayload.userName, payload.userName)
        XCTAssertEqual(decodedPayload.password, payload.password)
    }
    
    func testJoinRoomResultSerialization() throws {
        // Given
        let mockRoom = createMockRoom()
        let result = JoinRoomResult(room: mockRoom)
        
        // When: Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        
        // Then: Decode should work
        let decoder = JSONDecoder()
        let decodedResult = try decoder.decode(JoinRoomResult.self, from: data)
        
        XCTAssertEqual(decodedResult.room.id, mockRoom.id)
        XCTAssertEqual(decodedResult.room.title, mockRoom.title)
        XCTAssertEqual(decodedResult.room.game, mockRoom.game)
        XCTAssertEqual(decodedResult.room.password, mockRoom.password)
        XCTAssertEqual(decodedResult.room.maxPlayers, mockRoom.maxPlayers)
        XCTAssertEqual(decodedResult.room.hostName, mockRoom.hostName)
        XCTAssertEqual(decodedResult.room.players.count, mockRoom.players.count)
    }
    
    func testWSRequestSerialization() throws {
        // Given
        let payload = JoinRoomPayload(roomId: "test-123", userName: "User", password: "pass")
        let request = WSRequest<JoinRoomPayload>(
            action: .joinRoom,
            requestId: "req-123",
            payload: payload
        )
        
        // When: Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        // Then: Decode should work
        let decoder = JSONDecoder()
        let decodedRequest = try decoder.decode(WSRequest<JoinRoomPayload>.self, from: data)
        
        XCTAssertEqual(decodedRequest.action, .joinRoom)
        XCTAssertEqual(decodedRequest.requestId, "req-123")
        XCTAssertEqual(decodedRequest.payload?.roomId, "test-123")
        XCTAssertEqual(decodedRequest.payload?.userName, "User")
        XCTAssertEqual(decodedRequest.payload?.password, "pass")
    }
    
    func testWSResponseWithSuccessPayload() throws {
        // Given
        let mockRoom = createMockRoom()
        let result = JoinRoomResult(room: mockRoom)
        let response = WSResponse<JoinRoomResult>(
            action: .joinRoom,
            requestId: "req-123",
            error: nil,
            payload: result
        )
        
        // When: Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        // Then: Decode should work
        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(WSResponse<JoinRoomResult>.self, from: data)
        
        XCTAssertEqual(decodedResponse.action, .joinRoom)
        XCTAssertEqual(decodedResponse.requestId, "req-123")
        XCTAssertNil(decodedResponse.error)
        XCTAssertNotNil(decodedResponse.payload)
        XCTAssertEqual(decodedResponse.payload?.room.id, mockRoom.id)
    }
    
    func testWSResponseWithError() throws {
        // Given
        let response = WSResponse<JoinRoomResult>(
            action: .joinRoom,
            requestId: "req-123",
            error: "Invalid password",
            payload: nil
        )
        
        // When: Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        // Then: Decode should work
        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(WSResponse<JoinRoomResult>.self, from: data)
        
        XCTAssertEqual(decodedResponse.action, .joinRoom)
        XCTAssertEqual(decodedResponse.requestId, "req-123")
        XCTAssertEqual(decodedResponse.error, "Invalid password")
        XCTAssertNil(decodedResponse.payload)
    }
    
    // MARK: - Room Model Tests
    func testRoomModelValidation() {
        let mockRoom = createMockRoom()
        
        XCTAssertEqual(mockRoom.id, "test-room-123")
        XCTAssertEqual(mockRoom.title, "테스트 방")
        XCTAssertEqual(mockRoom.game, "BombParty")
        XCTAssertEqual(mockRoom.password, "1234")
        XCTAssertEqual(mockRoom.maxPlayers, 4)
        XCTAssertEqual(mockRoom.hostName, "테스트호스트")
        XCTAssertEqual(mockRoom.players.count, 1)
        XCTAssertTrue(mockRoom.players.first?.isHost ?? false)
    }
    
    func testPlayerModelValidation() {
        let player = Player(
            id: "player-123",
            name: "TestPlayer",
            isReady: false,
            role: "spy",
            isHost: true
        )
        
        XCTAssertEqual(player.id, "player-123")
        XCTAssertEqual(player.name, "TestPlayer")
        XCTAssertFalse(player.isReady)
        XCTAssertEqual(player.role, "spy")
        XCTAssertTrue(player.isHost)
    }
    
    // MARK: - WSAction Tests
    func testWSActionRawValues() {
        XCTAssertEqual(WSAction.fetchRooms.rawValue, "fetchRooms")
        XCTAssertEqual(WSAction.createRoom.rawValue, "createRoom")
        XCTAssertEqual(WSAction.joinRoom.rawValue, "joinRoom")
        XCTAssertEqual(WSAction.leaveRoom.rawValue, "leaveRoom")
        XCTAssertEqual(WSAction.toggleReady.rawValue, "toggleReady")
        XCTAssertEqual(WSAction.setRole.rawValue, "setRole")
        XCTAssertEqual(WSAction.startGame.rawValue, "startGame")
    }
    
    // MARK: - Performance Tests  
    func testJoinRoomPayloadEncodingPerformance() {
        let payload = JoinRoomPayload(
            roomId: "test-room-123",
            userName: "TestUser",
            password: "1234"
        )
        
        measure {
            for _ in 0..<1000 {
                let encoder = JSONEncoder()
                _ = try? encoder.encode(payload)
            }
        }
    }
    
    func testRoomModelCreationPerformance() {
        measure {
            for i in 0..<1000 {
                _ = Room(
                    id: "room-\(i)",
                    title: "Room \(i)",
                    game: "BombParty",
                    password: "pass\(i)",
                    maxPlayers: 4,
                    hostName: "Host\(i)",
                    players: []
                )
            }
        }
    }
}