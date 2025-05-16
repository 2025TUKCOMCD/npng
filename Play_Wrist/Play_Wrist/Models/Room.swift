import Foundation

// ✅ 서버에서 사용할 고유 ID를 갖는 Room 모델
struct Room: Identifiable {
    let id: Int                     // 🔥 고정된 roomID (서버에서 받는 Int)
    let title: String
    let game: String
    let password: String
    let maxPlayers: Int
    let hostName: String
    var players: [String]
}

// ✅ 서버 응답용 Room 구조체 (JSON 디코딩용)
struct RoomResponse: Codable {
    let id: Int
    let title: String
    let game: String
    let password: String
    let max_players: Int
}

// ✅ RoomResponse → Room 변환 함수
func convert(response: RoomResponse, hostName: String, players: [String]) -> Room {
    return Room(
        id: response.id,
        title: response.title,
        game: response.game,
        password: response.password,
        maxPlayers: response.max_players,
        hostName: hostName,
        players: players
    )
}
