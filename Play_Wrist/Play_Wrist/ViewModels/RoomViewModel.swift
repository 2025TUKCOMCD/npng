import Foundation

// MARK: - Player & Room Models

struct Player: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    var isReady: Bool
    var role: String?
    var isHost: Bool

    init(name: String, isHost: Bool = false) {
        self.id = UUID().uuidString
        self.name = name
        self.isReady = isHost   // 방장은 자동으로 true 고정
        self.role = nil
        self.isHost = isHost
    }
}


// MARK: - ViewModel

@MainActor
class RoomViewModel: ObservableObject {
    @Published var rooms: [Room] = []
    @Published var room: Room?

    // 방 생성
    func createRoom(title: String, game: String, password: String, maxPlayers: Int, hostName: String) {
        let hostPlayer = Player(name: hostName, isHost: true)

        let newRoom = Room(
            id: UUID().uuidString,      // UUID 사용
            title: title,
            game: game,
            password: password,
            maxPlayers: maxPlayers,
            hostName: hostName,
            players: [hostPlayer]       // 방장을 Player 객체로 추가
        )

        rooms.append(newRoom)
        room = newRoom
    }

    // 방 입장 (roomId 기준) - 권장
    @discardableResult
    func joinRoom(roomId: String, userName: String, inputPassword: String) -> Bool {
        guard let index = rooms.firstIndex(where: { $0.id == roomId }) else { return false }

        // 비밀번호 검사
        guard rooms[index].password == inputPassword else { return false }

        // 중복 닉네임 방지
        if rooms[index].players.contains(where: { $0.name == userName }) {
            return true // 이미 들어와 있으면 성공으로 간주 (원하면 false로 바꿔도 됨)
        }

        // 인원 제한
        guard rooms[index].players.count < rooms[index].maxPlayers else { return false }

        // 플레이어 추가
        rooms[index].players.append(Player(name: userName))

        // 현재 선택된 room도 동기화
        if room?.id == roomId {
            room = rooms[index]
        }
        return true
    }

    // 방 입장 (Room 값 전달 버전) - 기존 호출 호환용
    @discardableResult
    func joinRoom(_ targetRoom: Room, userName: String, inputPassword: String) -> Bool {
        return joinRoom(roomId: targetRoom.id, userName: userName, inputPassword: inputPassword)
    }

    // 방 나가기
    func leaveRoom(roomId: String, playerId: String) {
        guard let index = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        rooms[index].players.removeAll { $0.id == playerId }

        // 현재 선택된 room도 동기화
        if room?.id == roomId {
            room = rooms[index]
        }
    }

    // Ready 토글
    @discardableResult
    func toggleReady(roomId: String, playerId: String) -> Bool {
        guard let roomIndex = rooms.firstIndex(where: { $0.id == roomId }) else { return false }
        guard let playerIndex = rooms[roomIndex].players.firstIndex(where: { $0.id == playerId }) else { return false }

        rooms[roomIndex].players[playerIndex].isReady.toggle()

        if room?.id == roomId {
            room = rooms[roomIndex]
        }
        return true
    }

    // 역할 설정(예: "Spy", "Citizen" 등)
    func setRole(roomId: String, playerId: String, role: String?) {
        guard let roomIndex = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        guard let playerIndex = rooms[roomIndex].players.firstIndex(where: { $0.id == playerId }) else { return }

        rooms[roomIndex].players[playerIndex].role = role

        if room?.id == roomId {
            room = rooms[roomIndex]
        }
    }
}
