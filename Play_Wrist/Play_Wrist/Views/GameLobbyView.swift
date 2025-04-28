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
            let fullPlayers = room.players + Array(repeating: "", count: max(0, room.maxPlayers - room.players.count))
            let mid = fullPlayers.count / 2
            let left = Array(fullPlayers.prefix(mid))
            let right = Array(fullPlayers.suffix(from: mid))

            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 16) {
                    ForEach(left.indices, id: \.self) { index in
                        playerCard(name: left[index], isReady: playerStates[left[index]] == "Ready")
                    }
                }

                VStack(spacing: 16) {
                    ForEach(right.indices, id: \.self) { index in
                        playerCard(name: right[index], isReady: playerStates[right[index]] == "Ready")
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // ✅ 버튼 영역 (방장/유저 분기)
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
                // 🔥 일반 유저 → Ready 버튼
                Button(action: {
                    let userName = authViewModel.userName ?? "이름 없음"
                    playerStates[userName] = "Ready"
                }) {
                    Text("Ready")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
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

    // ✅ 유저 상태 초기화 (처음엔 모두 Normal)
    private func initializePlayerStates() {
        for player in room.players {
            playerStates[player] = "Normal"
        }
    }

    // ✅ Start 버튼 눌렀을 때 Ready인 유저들만 Watch로 전송
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
        // 방장 본인도 보내기
        let hostName = authViewModel.userName ?? "방장"
        let hostMessage: [String: Any] = [
            "event": "playerReady",
            "userName": hostName,
            "status": "Ready"
        ]
        PhoneWatchConnector.shared.send(message: hostMessage)
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
