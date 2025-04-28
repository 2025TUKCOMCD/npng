import SwiftUI

struct GameLobbyView: View {
    let room: Room
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var playerStates: [String: String] = [:] // 🔥 유저 상태 저장 (Normal / Ready)

    var body: some View {
        VStack(spacing: 16) {
            // ✅ 상단 바
            HStack {
                Button(action: {
                    dismiss()
                }) {
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

            // ✅ 게임명 카드
            Text(room.game)
                .foregroundColor(.purple)
                .font(.headline)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple, lineWidth: 1)
                )

            // ✅ 사용자 카드 리스트
            let fullPlayers = getFullPlayers()

            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 16) {
                    ForEach(Array(fullPlayers.prefix(fullPlayers.count / 2)).indices, id: \.self) { index in
                        let player = fullPlayers[index]
                        playerCard(
                            name: player,
                            isReady: !player.isEmpty && playerStates[player] == "Ready"
                        )
                    }
                }

                VStack(spacing: 16) {
                    ForEach(Array(fullPlayers.suffix(fullPlayers.count - fullPlayers.count / 2)).indices, id: \.self) { index in
                        let player = fullPlayers[fullPlayers.count / 2 + index]
                        playerCard(
                            name: player,
                            isReady: !player.isEmpty && playerStates[player] == "Ready"
                        )
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // ✅ 버튼 영역 (방장/유저 구분)
            if authViewModel.userName == room.hostName {
                // 🔥 방장 → Start 버튼
                Button(action: {
                    sendReadyPlayersToWatch()
                }) {
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
                // 🔥 일반 유저 → Ready <-> Normal 토글 버튼
                let userName = authViewModel.userName ?? "이름 없음"
                let isReady = playerStates[userName] == "Ready"

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
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            initializePlayerStates()
        }
    }

    // ✅ 전체 유저 리스트 생성 (본인 이름 보장)
    private func getFullPlayers() -> [String] {
        var playersSet = Set(room.players)
        playersSet.insert(room.hostName) // 방장 이름도 확실히 추가
        let players = Array(playersSet)
        let maxCount = room.maxPlayers
        return players + Array(repeating: "", count: max(0, maxCount - players.count))
    }

    // ✅ 유저 상태 초기화 (방장만 Ready, 나머지는 Normal)
    private func initializePlayerStates() {
        var playersSet = Set(room.players)
        playersSet.insert(room.hostName) // 방장 이름 강제 추가

        for player in playersSet {
            if player == room.hostName {
                playerStates[player] = "Ready" // 방장은 무조건 Ready
            } else {
                playerStates[player] = "Normal" // 나머지는 Normal
            }
        }
    }

    // ✅ Start 버튼 눌렀을 때 Ready 유저들만 Watch로 전송
    private func sendReadyPlayersToWatch() {
        for (player, state) in playerStates {
            if state == "Ready" {
                let message: [String: Any] = [
                    "event": "playerReady",
                    "userName": player,
                    "status": "Ready"
                ]
                PhoneWatchConnector.shared.send(message: message)
            }
        }
    }

    // ✅ 사용자 카드 뷰
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
