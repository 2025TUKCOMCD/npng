import SwiftUI

struct RoomJoinView: View {
    var room: Room
    @ObservedObject var roomViewModel: RoomViewModel
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var password = ""
    @State private var showAlert = false
    @State private var navigateToLobby = false

    var body: some View {
        VStack(spacing: 20) {
            // ✅ 방 정보 표시
            Text(room.title)
                .font(.title2)
                .bold()

            Text("게임: \(room.game)")
                .foregroundColor(.gray)

            Text("방장: \(room.hostName)")
                .foregroundColor(.gray)

            // ✅ 비밀번호 입력
            SecureField("비밀번호 입력", text: $password)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

            // ✅ 입장 버튼
            Button("입장하기") {
                let success = roomViewModel.joinRoom(room, userName: authViewModel.userName ?? "User", inputPassword: password)
                if success {
                    navigateToLobby = true
                } else {
                    showAlert = true
                }
            }
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .navigationTitle("방 정보")
        .background(
            NavigationLink(
                destination: GameLobbyView(room: roomViewModel.room ?? room)
                    .environmentObject(authViewModel),
                isActive: $navigateToLobby
            ) {
                EmptyView()
            }
        )
        .alert("비밀번호가 틀렸습니다.", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        }
    }
}
