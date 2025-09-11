import SwiftUI
import FirebaseAuth

struct GameLobbyView: View {
    let room: Room

    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @EnvironmentObject var roomViewModel: RoomViewModel    // ✅ 상위에서 주입되어야 함
    @Environment(\.dismiss) private var dismiss

    @State private var playerStates: [String: String] = [:]
    @State private var shouldNavigateToBombParty = false
    @State private var shouldNavigateToSpyFall = false

    private var fullPlayers: [String] { getFullPlayers() }
    private var leftPlayers: [String] { Array(fullPlayers.prefix(fullPlayers.count / 2)) }
    private var rightPlayers: [String] { Array(fullPlayers.suffix(fullPlayers.count - fullPlayers.count / 2)) }

    var body: some View {
        VStack(spacing: 16) {
            // 상단 바
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("게임 선택")
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
                Text("Play Wrist")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.purple)

            // 게임명 카드
            Text(room.game)
                .foregroundColor(.purple)
                .font(.headline)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple, lineWidth: 1)
                )

            // 사용자 카드 리스트
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 16) {
                    ForEach(leftPlayers.indices, id: \.self) { index in
                        let player = leftPlayers[index]
                        playerCard(name: player, isReady: isPlayerReady(player))
                    }
                }
                VStack(spacing: 16) {
                    ForEach(rightPlayers.indices, id: \.self) { index in
                        let player = rightPlayers[index]
                        playerCard(name: player, isReady: isPlayerReady(player))
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // 🔹 버튼 영역
            if authViewModel.userName == room.hostName {
                Button(action: startGameTapped) {
                    Text("Start")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            } else {
                let userName = authViewModel.userName ?? "이름 없음"
                let isReady = isPlayerReady(userName)

                Button(action: {
                    playerStates[userName] = isReady ? "Normal" : "Ready"
                }) {
                    Text(isReady ? "Normal" : "Ready")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isReady ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }

            // Navigation Links
            NavigationLink(
                destination: BombPartyGamePlayView(room: room).environmentObject(authViewModel),
                isActive: $shouldNavigateToBombParty
            ) { EmptyView() }

            NavigationLink(
                destination: SpyFallGamePlayView(room: room).environmentObject(authViewModel),
                isActive: $shouldNavigateToSpyFall
            ) { EmptyView() }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear { initializePlayerStates() }
    }

    // MARK: - Actions

    private func startGameTapped() {
        guard let user = Auth.auth().currentUser else { return }

        user.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("❌ [startGame] 토큰 가져오기 실패: \(error.localizedDescription)")
                return
            }
            guard let idToken = idToken else {
                print("❌ [startGame] idToken nil")
                return
            }

            // ✅ EnvironmentObject에서 직접 메서드 호출 (주의: 절대 $roomViewModel 아님)

            // 필요 시 즉시 전환 (서버 푸시 대기 없이)
            DispatchQueue.main.async {
                if room.game == "Bomb Party" {
                    sendReadyPlayersToWatch()
                    shouldNavigateToBombParty = true
                    PhoneWatchConnector.shared.send(message: ["event": "startGame", "gameType": "BombParty"])
                } else if room.game == "SPY Fall" {
                    shouldNavigateToSpyFall = true
                    PhoneWatchConnector.shared.send(message: ["event": "startGame", "gameType": "SpyFall"])
                }
            }
        }
    }

    // MARK: - Helpers

    private func isPlayerReady(_ name: String) -> Bool {
        !name.isEmpty && playerStates[name] == "Ready"
    }

    private func getFullPlayers() -> [String] {
        // Player → 이름만 추출해서 Set<String> 사용 (Hashable 에러 회피)
        var names = Set(room.players.map { $0.name })
        names.insert(room.hostName)
        let players = Array(names)
        return players + Array(repeating: "", count: max(0, room.maxPlayers - players.count))
    }

    private func initializePlayerStates() {
        var names = Set(room.players.map { $0.name })
        names.insert(room.hostName)
        for name in names {
            playerStates[name] = (name == room.hostName) ? "Ready" : "Normal"
        }
    }

    private func sendReadyPlayersToWatch() {
        for (player, state) in playerStates where state == "Ready" {
            let message: [String: Any] = ["event": "playerReady", "userName": player, "status": "Ready"]
            PhoneWatchConnector.shared.send(message: message)
        }
    }

    func playerCard(name: String, isReady: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.purple)

            Text(name.isEmpty ? "대기 중..." : name)
                .font(.body)
                .foregroundColor(.black)

            Text(isReady ? "Ready" : "Normal")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isReady ? .orange : .gray)
        }
        .frame(width: 80, height: 90)
        .padding()
        .background(Color.purple.opacity(0.15))
        .cornerRadius(16)
    }
}
