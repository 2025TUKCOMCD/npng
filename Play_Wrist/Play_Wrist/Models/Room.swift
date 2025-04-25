import Foundation

struct Room {
    let title: String
    let game: String
    let password: String
    let maxPlayers: Int
    let hostName: String
    var players: [String]
}
