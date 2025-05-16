
import Foundation

class RoomViewModel: ObservableObject {
    @Published var rooms: [Room] = []
    @Published var room: Room?

    func createRoom(title: String, game: String, password: String, maxPlayers: Int, hostName: String) {
        let newRoom = Room(
            id: Int.random(in: 1000...9999),            title: title,
            game: game,
            password: password,
            maxPlayers: maxPlayers,
            hostName: hostName,
            players: [hostName]
        )
        rooms.append(newRoom)
        room = newRoom
    }

    func joinRoom(_ room: Room, userName: String, inputPassword: String) -> Bool {
        guard room.password == inputPassword else { return false }

        var updatedRoom = room
        updatedRoom.players.append(userName)
        self.room = updatedRoom
        return true
    }
}
