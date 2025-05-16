import SwiftUI

struct RoomListView: View {
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @StateObject private var roomViewModel = RoomViewModel()
    @State private var selectedRoom: Room?
    @State private var navigateToJoin = false

    var body: some View {
        VStack {
            Text("방 목록")
                .font(.largeTitle)
                .padding()

            List(roomViewModel.rooms, id: \.title) { room in
                Button(action: {
                    selectedRoom = room
                    navigateToJoin = true
                }) {
                    VStack(alignment: .leading) {
                        Text(room.title).font(.headline)
                        Text("게임: \(room.game) • 인원: \(room.players.count)/\(room.maxPlayers)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            NavigationLink(
                destination: selectedRoom.map { room in
                    RoomJoinView(room: room, roomViewModel: roomViewModel)
                        .environmentObject(authViewModel)
                },
                isActive: $navigateToJoin
            ) {
                EmptyView()
            }
        }
        .navigationTitle("방 찾기")
        .onAppear {
            if roomViewModel.rooms.isEmpty {
                let testRoom = Room(
                    id: Int.random(in: 1000...9999),
                    title: "🛠 테스트용 예비방",
                    game: "폭탄 넘기기",
                    password: "test",
                    maxPlayers: 4,
                    hostName: "테스트유저",
                    players: ["테스트유저"]
                )
                roomViewModel.rooms.append(testRoom)
            }
        }
    }
}
