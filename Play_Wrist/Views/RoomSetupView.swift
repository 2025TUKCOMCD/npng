import SwiftUI
import WatchConnectivity

struct RoomSetupView: View {
    var selectedGame: String
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @EnvironmentObject var roomViewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var roomTitle = ""
    @State private var password = ""
    @State private var playerCount = "4"
    @State private var shouldNavigate = false

    // ✅ roomViewModel.room이 아직 없을 때 NavigationLink용 임시 값
    private var fallbackRoom: Room {
        Room(
            id: "temp",
            title: roomTitle.isEmpty ? "로딩 중…" : roomTitle,
            game: selectedGame,
            password: "",
            maxPlayers: Int(playerCount) ?? 4,
            hostName: authViewModel.userName ?? "user1",
            players: []
        )
    }

    var body: some View {
        ZStack {
            Color.gray.opacity(0.3).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // 닫기 버튼
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
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
                        Button {
                            let host = authViewModel.userName ?? "user1"
                            roomViewModel.createRoom(
                                title: roomTitle,
                                game: selectedGame,
                                password: password,
                                maxPlayers: Int(playerCount) ?? 4,
                                hostName: host
                            )
                            
                            // 방 생성 후 네비게이션은 room이 업데이트되면 자동으로 처리
                        } label: {
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
                        .disabled(roomTitle.isEmpty)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            // ✅ 값(Room) 전달 — 절대 $roomViewModel.room (Binding) 쓰지 마세요
            NavigationLink(
                destination: GameLobbyView(
                    roomId: roomViewModel.room?.id ?? ""  // 빈 문자열로 시작, GameLobbyView에서 처리
                )
                .environmentObject(authViewModel)
                .environmentObject(roomViewModel)
                .onDisappear {
                    // 방 나가기는 GameLobbyView에서 처리
                },
                isActive: $shouldNavigate
            ) { EmptyView() }
        }
        .navigationTitle("방 만들기")
        .onChange(of: roomViewModel.room?.id) { newRoomId in
            // 방이 생성되면 자동으로 네비게이션 (약간의 딜레이 추가)
            if newRoomId != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    shouldNavigate = true
                }
            }
        }
    }

    // MARK: - Inputs

    private func inputSection(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
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

    private func inputSecureSection(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
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
