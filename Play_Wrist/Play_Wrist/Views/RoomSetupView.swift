import SwiftUI
import WatchConnectivity

struct RoomSetupView: View {
    var selectedGame: String
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @StateObject private var roomViewModel = RoomViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var roomTitle = ""
    @State private var password = ""
    @State private var playerCount = "4"
    @State private var shouldNavigate = false

    var body: some View {
        ZStack {
            Color.gray.opacity(0.3).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // 닫기 버튼
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.top)

                    // 입력 영역
                    VStack(alignment: .leading, spacing: 20) {
                        inputSection(title: "방 제목", placeholder: "재밌는 게임 해요~", text: $roomTitle)
                        inputSecureSection(title: "비밀번호", placeholder: "********", text: $password)
                        inputSection(title: "인원 수", placeholder: "4", text: $playerCount, keyboard: .numberPad)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding(.horizontal)

                    // 다음 버튼
                    HStack {
                        Spacer()
                        Button(action: {
                            let host = authViewModel.userName ?? "user1"
                            roomViewModel.createRoom(
                                title: roomTitle,
                                game: selectedGame,
                                password: password,
                                maxPlayers: Int(playerCount) ?? 4,
                                hostName: host
                            )
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                shouldNavigate = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 60, height: 60)
                                    .shadow(radius: 10)

                                Image(systemName: "arrow.right")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            // ✅ NavigationLink는 ZStack 안, ScrollView 밖
            NavigationLink(
                destination: GameLobbyView(
                    room: roomViewModel.room ?? Room(
                        id: -1,
                        title: "에러",
                        game: selectedGame,
                        password: "",
                        maxPlayers: 4,
                        hostName: "???",
                        players: []
                    )
                ).environmentObject(authViewModel),
                isActive: $shouldNavigate
            ) {
                EmptyView()
            }
        }
        .navigationTitle("방 만들기")
    }

    // 일반 텍스트 필드
    private func inputSection(title: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.purple)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
        }
    }

    // 비밀번호 필드
    private func inputSecureSection(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.purple)

            SecureField(placeholder, text: text)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
        }
    }
}
