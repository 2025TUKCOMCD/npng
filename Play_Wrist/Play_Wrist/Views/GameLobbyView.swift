import SwiftUI

struct GameLobbyView: View {
    let room: Room
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            // 상단 바
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

            // 사용자 카드
            let fullPlayers = room.players + Array(repeating: "", count: max(0, room.maxPlayers - room.players.count))
            let mid = fullPlayers.count / 2
            let left = Array(fullPlayers.prefix(mid))
            let right = Array(fullPlayers.suffix(from: mid))

            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 16) {
                    ForEach(left.indices, id: \.self) { index in
                        playerCard(name: left[index], isReady: true)
                    }
                }

                VStack(spacing: 16) {
                    ForEach(right.indices, id: \.self) { index in
                        playerCard(name: right[index], isReady: true)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // 버튼 영역: Start + Watch
            HStack(spacing: 16) {
                // ✅ Start 버튼
                Button(action: {
                    let maxPlayers = room.maxPlayers
                    let players = (1...maxPlayers).map { "player\($0)" }
                    let assignedPlayer = players.randomElement() ?? "player1"

                    let message: [String: Any] = [
                        "event": "gameStart",
                        "assignedPlayer": assignedPlayer,
                        "status": "Ready"
                    ]

                    PhoneWatchConnector.shared.send(message: message)
                }) {
                    Text("Start")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                // ✅ Watch 버튼
                Button(action: {
                    let userName = authViewModel.userName ?? "이름 없음"

                    let message: [String: Any] = [
                        "event": "playerReady",
                        "userName": userName,
                        "status": "Ready"
                    ]

                    PhoneWatchConnector.shared.send(message: message)
                }) {
                    Text("Watch")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    // ✅ 사용자 카드 뷰 함수 (body 바깥에 반드시 있어야 함!)
    func playerCard(name: String, isReady: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.purple)

            Text(name.isEmpty ? "대기 중..." : name)
                .font(.body)
                .foregroundColor(.black)

            if isReady {
                Text("Ready")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
        }
        .frame(width: 80, height: 90)
        .padding()
        .background(Color.purple.opacity(0.15))
        .cornerRadius(16)
    }
}
