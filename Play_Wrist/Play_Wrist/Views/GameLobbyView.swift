import SwiftUI

struct GameLobbyView: View {
    let room: Room
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var playerStates: [String: String] = [:] // 🔥 유저 상태 저장 (Normal / Ready)
    @State private var shouldNavigateToBombParty = false    // 🔥 게임 화면으로 이동 플래그

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
                    sendReadyPlayersToWatch()            // 🔥 Ready 상태 Watch 전송
                    assignPlayersAndSendToWatch()        // 🔥 Player 번호/폭탄 상태 Watch 전송
                    shouldNavigateToBombParty = true     // 🔥 게임 화면으로 이동
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

            // ✅ BombPartyGamePlayView로 이동하는 NavigationLink 추가
            NavigationLink(
                destination: BombPartyGamePlayView(room: room).environmentObject(authViewModel),
                isActive: $shouldNavigateToBombParty
            ) {
                EmptyView()
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            initializePlayerStates()
        }
    }

    // ✅ 유저 리스트 생성
    private func getFullPlayers() -> [String] {
        var playersSet = Set(room.players)
        playersSet.insert(room.hostName)
        let players = Array(playersSet)
        let maxCount = room.maxPlayers
        return players + Array(repeating: "", count: max(0, maxCount - players.count))
    }

    // ✅ 유저 상태 초기화
    private func initializePlayerStates() {
        var playersSet = Set(room.players)
        playersSet.insert(room.hostName)

        for player in playersSet {
            if player == room.hostName {
                playerStates[player] = "Ready"
            } else {
                playerStates[player] = "Normal"
            }
        }
    }

    // ✅ Ready 유저 Watch로 전송
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

    // 🔥 추가: Player 번호/폭탄 상태 Watch로 전송
    private func assignPlayersAndSendToWatch() {
        var players = room.players
        players.append(room.hostName)
        players = Array(Set(players)) // 중복 제거

        if players.count > room.maxPlayers {
            players = Array(players.prefix(room.maxPlayers))
        }

        players.shuffle()

        let bombHolder = players.randomElement()

        for (index, player) in players.enumerated() {
            let playerNumber = "Player\(index + 1)"
            let hasBomb = (player == bombHolder)

            let message: [String: Any] = [
                "event": "assignPlayer",
                "playerNumber": playerNumber,
                "hasBomb": hasBomb
            ]

            PhoneWatchConnector.shared.sendToSpecificWatch(for: player, message: message) // 🔥 수정 필요
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
