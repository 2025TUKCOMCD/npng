import Foundation
import Combine

// MARK: - Models


struct Room: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let game: String
    let password: String
    let maxPlayers: Int
    let hostName: String
    var players: [Player]
}

// MARK: - WebSocket Message Protocol

enum WSAction: String, Codable {
    // 헬스체크/에러
    case ping, pong, error

    // 요청(Request)
    case fetchRooms
    case createRoom
    case joinRoom
    case leaveRoom
    case toggleReady
    case setRole
    case startGame

    // 서버 푸시(Push/Broadcast)
    case roomsUpdated
    case joined
    case left           
    case playerUpdated
    case gameStarted
}

struct WSRequest<T: Codable>: Codable {
    let action: WSAction
    let requestId: String
    let payload: T?
}

struct WSResponse<T: Codable>: Codable {
    let action: WSAction
    let requestId: String?
    let payload: T?
    let error: String?
}

// MARK: - Payloads

struct FetchRoomsPayload: Codable { } // 빈 페이로드

struct CreateRoomPayload: Codable {
    let room: Room
}

struct JoinRoomPayload: Codable {
    let roomId: String
    let userName: String
    let password: String
}

struct LeaveRoomPayload: Codable {
    let roomId: String
    let playerId: String
}

struct ToggleReadyPayload: Codable {
    let roomId: String
    let playerId: String
}

struct SetRolePayload: Codable {
    let roomId: String
    let playerId: String
    let role: String?  // nil이면 역할 제거
}

struct StartGamePayload: Codable {
    let roomId: String
    let idToken: String
}

// MARK: - Results (응답 바디)
struct RoomsUpdatedPayload: Codable {
    let rooms: [Room]
}

struct JoinedPayload: Codable {
    let room: Room
}

struct LeftPayload: Codable {
    let room: Room
}

struct PlayerUpdatedPayload: Codable {
    let room: Room
}

struct CreateRoomResult: Codable {
    let room: Room
}

struct JoinRoomResult: Codable {
    let room: Room
}

struct LeaveRoomResult: Codable {
    let room: Room
}

struct ToggleReadyResult: Codable {
    let room: Room
}

struct SetRoleResult: Codable {
    let room: Room
}

struct StartGameResult: Codable {
    let success: Bool
}
