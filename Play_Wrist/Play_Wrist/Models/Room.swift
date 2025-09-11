import Foundation
import Combine


// MARK: - 액션 키워드 (서버와 문자열 일치시켜야 함)
enum WSAction: String, Codable {
    // 요청/응답
    case fetchRooms, createRoom, joinRoom, leaveRoom, toggleReady, setRole, startGame
    // 핑퐁
    case ping, pong
    // 서버 푸시
    case roomsUpdated, joined, left, playerUpdated, gameStarted
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
    let id: String
    let name: String
    var isReady: Bool
    var role: String?
    var isHost: Bool
}

struct Room: Codable, Identifiable, Equatable {
    let id: String            // 서버가 숫자를 주면 클라에서 문자열로 변환해서 넣어도 OK
    let title: String
    let game: String
    let password: String
    let maxPlayers: Int
    let hostName: String
    var players: [Player]
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
struct StartGamePayload: Codable { let roomId: String, idToken: String }
struct StartGameResult: Codable { let success: Bool }
