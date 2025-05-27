import SwiftUI

struct SpyFallGamePlayView: View {
    let room: Room
    @EnvironmentObject var authViewModel: AppleSignInViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Spy Fall Game play ")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .padding()

            Text("방 제목: \(room.title)")
                .font(.title2)
                .padding()

            Text("게임 참가자: \(room.players.joined(separator: ", "))")
                .font(.body)
                .padding()

            Spacer()

            // 추가: 시작하면서 Watch로 게임 시작 메시지 전송
            Button(action: {
                sendGameStartToWatch()
            }) {
                Text("Apple Watch로 '게임 시작' 보내기")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .onAppear {
            sendGameStartToWatch() // 🔥 화면 진입 시에도 바로 전송
        }
        .background(Color.white.ignoresSafeArea())
    }

    // ✅ Watch로 '게임 시작' 메시지 보내기
    private func sendGameStartToWatch() {
        let message: [String: Any] = [
            "event": "gameStart",
            "game": "Bomb Party"
        ]
        PhoneWatchConnector.shared.send(message: message)
    }
}
