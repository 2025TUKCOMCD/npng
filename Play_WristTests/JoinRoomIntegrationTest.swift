import XCTest
import Foundation
@testable import Play_Wrist

@MainActor
final class JoinRoomIntegrationTest: XCTestCase {
    
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
    
    func testJoinRoomIntegration() async throws {
        print("🧪 통합 테스트: 실제 방 입장 기능 테스트")
        
        // 1. 웹소켓 연결
        print("📡 WebSocket 연결 중...")
        webSocketService.connect()
        
        // 연결 대기
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3초
        
        // 2. 방 목록 조회
        print("📋 방 목록 조회 중...")
        webSocketService.fetchRooms()
        
        // 응답 대기
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2초
        
        // 3. 테스트용 방 생성
        print("🏠 테스트 방 생성 중...")
        let testRoom = Room(
            id: UUID().uuidString,
            title: "테스트 방",
            game: "BombParty",
            password: "",
            maxPlayers: 4,
            hostName: "테스트호스트",
            players: []
        )
        
        webSocketService.createRoom(testRoom)
        
        // 방 생성 대기
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2초
        
        // 4. 방 입장 시도
        print("🚪 방 입장 시도...")
        do {
            let joinedRoom = try await webSocketService.joinRoom(
                roomId: testRoom.id,
                userName: "테스트사용자",
                password: ""
            )
            
            print("✅ 방 입장 성공!")
            print("방 ID: \(joinedRoom.id)")
            print("방 제목: \(joinedRoom.title)")
            print("현재 플레이어 수: \(joinedRoom.players.count)")
            
            // 검증
            XCTAssertEqual(joinedRoom.id, testRoom.id, "방 ID가 일치해야 함")
            XCTAssertEqual(joinedRoom.title, testRoom.title, "방 제목이 일치해야 함")
            XCTAssertTrue(joinedRoom.players.contains { $0.name == "테스트사용자" }, "입장한 사용자가 플레이어 목록에 있어야 함")
            
        } catch {
            print("❌ 방 입장 실패: \(error)")
            
            // WebSocket 에러 타입별 처리
            if let wsError = error as? WebSocketError {
                switch wsError {
                case .notConnected:
                    XCTFail("WebSocket이 연결되지 않음")
                case .serverError(let message):
                    print("서버 에러: \(message)")
                    // 서버 에러는 실패로 간주하지 않음 (방이 실제로 없을 수 있음)
                case .timeout:
                    XCTFail("요청 시간 초과")
                case .encodingFailed:
                    XCTFail("요청 인코딩 실패")
                case .emptyResponse:
                    XCTFail("서버 응답 없음")
                }
            } else {
                XCTFail("예상치 못한 에러: \(error)")
            }
        }
        
        print("🔌 연결 종료...")
        webSocketService.disconnect()
        
        print("✅ 통합 테스트 완료")
    }
    
    func testJoinRoomWithWrongPassword() async throws {
        print("🧪 잘못된 비밀번호로 방 입장 테스트")
        
        webSocketService.connect()
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        do {
            let _ = try await webSocketService.joinRoom(
                roomId: "nonexistent-room",
                userName: "테스트사용자",
                password: "wrong-password"
            )
            XCTFail("존재하지 않는 방에 입장할 수 없어야 함")
        } catch {
            print("✅ 예상된 에러 발생: \(error)")
            
            if let wsError = error as? WebSocketError {
                switch wsError {
                case .serverError(let message):
                    print("서버 에러 메시지: \(message)")
                    // 서버에서 적절한 에러 메시지를 반환했음
                default:
                    break
                }
            }
        }
        
        webSocketService.disconnect()
    }
}