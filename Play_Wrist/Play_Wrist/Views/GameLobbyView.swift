import SwiftUI

struct GameLobbyView: View {
    let room: Room
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var playerStates: [String: String] = [:]
    @State private var shouldNavigateToBombParty = false
    @State private var shouldNavigateToSpyFall = false

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
            let fullPlayers = getFullPlayers()
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 16) {
                    ForEach(Array(fullPlayers.prefix(fullPlayers.count / 2)).indices, id: \.self) { index in
                        let player = fullPlayers[index]
                        playerCard(name: player, isReady: isPlayerReady(player))
                    }
                }
                VStack(spacing: 16) {
                    ForEach(Array(fullPlayers.suffix(fullPlayers.count - fullPlayers.count / 2)).indices, id: \.self) { index in
                        let player = fullPlayers[fullPlayers.count / 2 + index]
                        playerCard(name: player, isReady: isPlayerReady(player))
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // 버튼 영역
            if authViewModel.userName == room.hostName {
                Button(action: {
                    if room.game == "Bomb Party" {
                        sendReadyPlayersToWatch()
                        assignPlayersAndSendToWatch()
                        shouldNavigateToBombParty = true
                    } else if room.game == "SPY Fall" {
                        sendSpyFallDataToWatch()
                        shouldNavigateToSpyFall = true
                    }
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
            NavigationLink(destination: BombPartyGamePlayView(room: room).environmentObject(authViewModel), isActive: $shouldNavigateToBombParty) { EmptyView() }

            NavigationLink(destination: SpyFallGamePlayView(room: room).environmentObject(authViewModel), isActive: $shouldNavigateToSpyFall) { EmptyView() }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear { initializePlayerStates() }
    }

    private func isPlayerReady(_ name: String) -> Bool {
        return !name.isEmpty && playerStates[name] == "Ready"
    }

    private func getFullPlayers() -> [String] {
        var playersSet = Set(room.players)
        playersSet.insert(room.hostName)
        let players = Array(playersSet)
        return players + Array(repeating: "", count: max(0, room.maxPlayers - players.count))
    }

    private func initializePlayerStates() {
        var playersSet = Set(room.players)
        playersSet.insert(room.hostName)
        for player in playersSet {
            playerStates[player] = (player == room.hostName) ? "Ready" : "Normal"
        }
    }

    private func sendReadyPlayersToWatch() {
        for (player, state) in playerStates where state == "Ready" {
            let message: [String: Any] = ["event": "playerReady", "userName": player, "status": "Ready"]
            PhoneWatchConnector.shared.send(message: message)
        }
    }

    private func assignPlayersAndSendToWatch() {
        var players = Array(Set(room.players + [room.hostName])).shuffled()
        let bombHolder = players.randomElement()

        for (i, player) in players.prefix(room.maxPlayers).enumerated() {
            let message: [String: Any] = [
                "event": "assignPlayer",
                "playerNumber": "Player\(i+1)",
                "hasBomb": (player == bombHolder)
            ]
            PhoneWatchConnector.shared.sendToSpecificWatch(for: player, message: message)
        }

        // ✅ 🔥 Bomb Party 화면 전환용 메시지 추가
        PhoneWatchConnector.shared.send(message: [
            "event": "startGame",
            "gameType": "BombParty"
        ])
    }


    
    private func sendSpyFallDataToWatch() {
        let locations: [String: [String]] = [
            "병원": ["의사", "간호사", "환자", "병문안 온 친구", "카운터 직원", "구급차 운전사", "전공의"],
            "공항": ["조종사", "승무원", "여행객", "보안요원", "테러리스트", "정비사", "안네데스크 직원"],
            "학교": ["학생", "선생님", "교장", "조리사", "보안관", "급식배달원", "학부모"],
            "해적선": ["노예", "일하는 사환", "포수", "뱃사람", "요리사", "죄수", "해적선 운전사"],
            "카지노": ["매니저", "사기꾼", "수석 보안 요원", "출입구 관리자", "바텐더", "딜러", "손님"],
            "중세 군대": ["수감된 아랍인", "수도승", "궁수", "주교", "하인", "기사", "캡틴"],
            "회사 송년회": ["비서", "불청객", "회계사", "매니저", "주임", "연예인", "부장님"]
        ]

        let selectedLocation = locations.keys.randomElement() ?? "병원"
        let roles = locations[selectedLocation] ?? ["시민"]

        var players = room.players + [room.hostName]
        players.shuffle()  // 🔄 플레이어 순서 섞기

        guard let spy = players.randomElement() else { return }
        var citizenRoles = roles.shuffled()

        for player in players {
            let isSpy = player == spy
            let citizenRole = isSpy ? "" : (citizenRoles.popLast() ?? "시민")

            let message: [String: Any] = [
                "event": "spyAssign",
                "userName": player,
                "role": isSpy ? "SPY" : "CITIZEN",
                "location": selectedLocation,
                "citizenRole": citizenRole
            ]

            PhoneWatchConnector.shared.sendToSpecificWatch(for: player, message: message)
            print("🔀 \(player): \(isSpy ? "SPY" : citizenRole), 장소: \(selectedLocation)")
        }

        PhoneWatchConnector.shared.send(message: [
            "event": "startGame",
            "gameType": "SpyFall"
        ])
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
