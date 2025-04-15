import SwiftUI

struct RoomJoinView: View {
    var room: Room?
    @ObservedObject var roomViewModel: RoomViewModel
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @State private var password = ""
    @State private var showAlert = false
    @State private var navigateToLobby = false

    var body: some View {
        VStack(spacing: 20) {
            if let room = room {
                Text(room.title)
                    .font(.title2)
                Text("게임: \(room.game)")
                Text("방장: \(room.hostName)")

                SecureField("비밀번호 입력", text: $password)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                Button("입장하기") {
                    if roomViewModel.joinRoom(room, userName: authViewModel.userName ?? "User", inputPassword: password) {
                        navigateToLobby = true
                    } else {
                        showAlert = true
                    }
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
                .alert("비밀번호가 틀렸습니다.", isPresented: $showAlert) {
                    Button("확인", role: .cancel) {}
                }

                NavigationLink(
                    destination: GameLobbyView(room: roomViewModel.room!).environmentObject(authViewModel),
                    isActive: $navigateToLobby
                ) {
                    EmptyView()
                }
            } else {
                Text("잘못된 접근입니다.")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("방 정보")
    }
}




