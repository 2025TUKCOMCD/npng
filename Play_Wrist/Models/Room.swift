import Foundation
import Combine


// MARK: - 액션 키워드 (서버와 문자열 일치시켜야 함)
enum WSAction: String, Codable {
    // 요청/응답
    case fetchRooms, createRoom, joinRoom, leaveRoom, toggleReady, setRole, startGame, passBomb
    // 핑퐁
    case ping, pong
    // 서버 푸시
    case roomsUpdated, joined, left, playerUpdated, gameStarted, bombExploded
    // 에러
    case error
}

// MARK: - 공통 래퍼
struct WSRequest<P: Codable>: Codable {
    let action: WSAction
    let requestId: String
    let payload: P?
}

struct WSResponse<P: Codable>: Codable {
    let action: WSAction
    let requestId: String?
    let error: String?
    let payload: P?
}

// MARK: - 모델
struct Player: Codable, Identifiable, Equatable {
    private let _id: String?
    let name: String
    var isReady: Bool
    var role: String?
    var isHost: Bool
    
    // Identifiable을 위한 computed property
    var id: String {
        return _id ?? UUID().uuidString
    }
    
    // Codable을 위한 CodingKeys
    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case name, isReady, role, isHost
    }
    
    // 초기화 메서드
    init(id: String?, name: String, isReady: Bool, role: String?, isHost: Bool) {
        self._id = id
        self.name = name
        self.isReady = isReady
        self.role = role
        self.isHost = isHost
    }
    
    // 편의 초기화 메서드 (기존 코드와의 호환성)
    init(id: String, name: String, isReady: Bool, role: String?, isHost: Bool) {
        self._id = id
        self.name = name
        self.isReady = isReady
        self.role = role
        self.isHost = isHost
    }
}

struct Room: Codable, Identifiable, Equatable {
    let id: String            // 서버가 숫자를 주면 클라에서 문자열로 변환해서 넣어도 OK
    let title: String
    let game: String
    let password: String
    let maxPlayers: Int
    let hostName: String
    var players: [Player]
    
    // 게임 상태 정보 (서버에서 추가 전송)
    var started: Bool?           // 게임 시작 여부
    var currentBombHolder: String?  // 현재 폭탄 가진 플레이어 ID
    var currentMission: String?     // 현재 미션
    var bombStartTime: Int64?       // 폭탄 시작 시각 (epoch millis)
    var bombDuration: Int64?        // 폭탄 제한시간 (ms)
}

// MARK: - 페이로드 (서비스 코드에서 참조하던 구조)
struct FetchRoomsPayload: Codable {}

struct RoomsUpdatedPayload: Codable { let rooms: [Room] }
struct JoinedPayload: Codable { let room: Room }
struct LeftPayload: Codable { let room: Room }
struct PlayerUpdatedPayload: Codable { let room: Room }

// 생성
struct CreateRoomPayload: Codable { let room: Room }
struct CreateRoomResult: Codable { let room: Room }

// 입장/퇴장
struct JoinRoomPayload: Codable { let roomId: String, userName: String, password: String }
struct JoinRoomResult: Codable { let room: Room }

struct LeaveRoomPayload: Codable { let roomId: String, playerId: String }
struct LeaveRoomResult: Codable { let room: Room }

// 준비/역할
struct ToggleReadyPayload: Codable { let roomId: String, playerId: String }
struct ToggleReadyResult: Codable { let room: Room }

struct SetRolePayload: Codable { let roomId: String, playerId: String, role: String? }
struct SetRoleResult: Codable { let room: Room }

// 게임 시작
struct StartGamePayload: Codable { let roomId: String }
struct StartGameResult: Codable { let success: Bool }

// 폭탄 전달
struct PassBombPayload: Codable { let roomId: String, playerId: String }
struct PassBombResult: Codable { let room: Room }

// MARK: - WebSocket 에러 타입
enum WebSocketError: Error, LocalizedError {
    case notConnected
    case encodingFailed
    case emptyResponse
    case serverError(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket이 연결되지 않았습니다"
        case .encodingFailed:
            return "요청 인코딩에 실패했습니다"
        case .emptyResponse:
            return "서버 응답이 비어있습니다"
        case .serverError(let message):
            return message
        case .timeout:
            return "요청 시간이 초과되었습니다"
        }
    }
}
