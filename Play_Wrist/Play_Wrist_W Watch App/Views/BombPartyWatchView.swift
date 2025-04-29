import SwiftUI
import WatchConnectivity

struct BombPartyWatchView: View {
    @StateObject private var sessionManager = WCSessionManager.shared

    var body: some View {
        VStack(spacing: 12) {
            // 타이틀
            Text("💣 Bomb Party")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            // 플레이어 번호
            VStack(spacing: 4) {
                Text("내 번호")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Text(sessionManager.playerNumber)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }

            // 폭탄 상태
            VStack(spacing: 4) {
                Text("폭탄 상태")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Text(sessionManager.hasBomb ? "O" : "X")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(sessionManager.hasBomb ? .red : .green)
            }

            // 폭탄 넘기기 버튼 또는 안내 텍스트
            if sessionManager.hasBomb {
                Button(action: {
                    sendPassBomb()
                }) {
                    Text("폭탄 넘기기")
                        .font(.headline)
                        .frame(maxWidth: 100)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 12)
            } else {
                Text("폭탄 없음")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.top, 12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .multilineTextAlignment(.center) // ✅ 텍스트 중앙 정렬
    }

    private func sendPassBomb() {
        let message: [String: Any] = [
            "event": "passBomb",
            "playerNumber": sessionManager.playerNumber
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
        sessionManager.hasBomb = false
    }
}
