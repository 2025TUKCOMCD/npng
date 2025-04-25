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
                destination: RoomJoinView(room: selectedRoom, roomViewModel: roomViewModel)
                    .environmentObject(authViewModel),
                isActive: $navigateToJoin
            ) {
                EmptyView()
            }
        }
        .navigationTitle("방 찾기")
    }
}

