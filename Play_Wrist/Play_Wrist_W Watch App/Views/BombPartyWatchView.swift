import SwiftUI
import WatchConnectivity

struct BombPartyWatchView: View {
    @StateObject private var sessionManager = WCSessionManager.shared
    @State private var missionCompleted: Bool = false   // 🔥 미션 완료 여부 추가

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

            // 미션 수행 버튼
            if sessionManager.hasBomb && !missionCompleted {
                Button(action: {
                    completeMission()
                }) {
                    Text("미션 수행")
                        .font(.headline)
                        .frame(maxWidth: 120)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 12)
            }

            // 폭탄 넘기기 버튼
            if sessionManager.hasBomb && missionCompleted {
                Button(action: {
                    sendPassBomb()
                }) {
                    Text("폭탄 넘기기")
                        .font(.headline)
                        .frame(maxWidth: 120)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 12)
            }

            // 폭탄 없음 안내
            if !sessionManager.hasBomb {
                Text("폭탄 없음")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.top, 12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .multilineTextAlignment(.center)
    }

    // ✅ 미션 수행 완료 처리
    private func completeMission() {
        missionCompleted = true
    }

    // ✅ 폭탄 넘기기
    private func sendPassBomb() {
        let message: [String: Any] = [
            "event": "passBomb",
            "playerNumber": sessionManager.playerNumber
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }

        sessionManager.hasBomb = false
        missionCompleted = false   // 🔥 다음 폭탄을 받을 때 다시 미션해야 하니까 초기화
    }
}
