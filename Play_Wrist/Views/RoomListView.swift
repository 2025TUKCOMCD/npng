import SwiftUI

struct RoomListView: View {
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @EnvironmentObject var roomViewModel: RoomViewModel
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
            print("🔍 [RoomListView] onAppear 호출됨")
            print("🔍 [RoomListView] 현재 방 개수: \(roomViewModel.rooms.count)")
            
            // WebSocket 연결 상태 확인 후 fetchRooms 호출
            Task {
                // WebSocket 연결 완료까지 대기
                var attempts = 0
                while !WebSocketService.shared.isConnected && attempts < 50 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                    attempts += 1
                }
                
                if WebSocketService.shared.isConnected {
                    print("🔍 [RoomListView] WebSocket 연결 확인됨, fetchRooms 호출")
                    await MainActor.run {
                        roomViewModel.fetchRooms()
                    }
                    
                    // 1초 후 방 목록 상태 확인
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1초
                    
                    await MainActor.run {
                        print("🔍 [RoomListView] 최종 방 목록: \(roomViewModel.rooms.count)개")
                        for room in roomViewModel.rooms {
                            print("  - \(room.title) (플레이어: \(room.players.count)/\(room.maxPlayers))")
                        }
                    }
                } else {
                    print("❌ [RoomListView] WebSocket 연결 실패")
                }
            }
        }
    }
}
