import SwiftUI

struct RoomJoinView: View {
    var room: Room
    @ObservedObject var roomViewModel: RoomViewModel
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = "비밀번호가 틀렸습니다."
    @State private var navigateToLobby = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            // 방 정보
            Text(room.title)
                .font(.title2)
                .bold()

            Text("게임: \(room.game)")
                .foregroundColor(.gray)

            Text("방장: \(room.hostName)")
                .foregroundColor(.gray)

            // 비밀번호
            SecureField("비밀번호 입력", text: $password)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

            // 입장 버튼
            Button {
                guard !isLoading else { return }
                isLoading = true
                let userName = authViewModel.userName ?? "User"

                Task {
                    do {
                        // ✅ WebSocket 비동기 요청
                        let joined = try await WebSocketService.shared.joinRoom(
                            roomId: room.id,              // Room.id가 String이어야 합니다
                            userName: userName,
                            password: password
                        )
                        // 성공 시 현재 방 갱신 후 이동
                        await MainActor.run {
                            roomViewModel.room = joined
                            navigateToLobby = true
                            isLoading = false
                        }
                    } catch {
                        await MainActor.run {
                            alertMessage = error.localizedDescription.isEmpty
                                ? "입장에 실패했습니다."
                                : error.localizedDescription
                            showAlert = true
                            isLoading = false
                        }
                    }
                }
            } label: {
                HStack {
                    if isLoading { ProgressView() }
                    Text("입장하기")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("방 정보")
        // ✅ 값(Room) 전달 — Binding 아님
        .background(
            NavigationLink(
                destination: GameLobbyView(room: roomViewModel.room ?? room)
                    .environmentObject(authViewModel),
                isActive: $navigateToLobby
            ) { EmptyView() }
        )
        .alert("입장 실패", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
}
