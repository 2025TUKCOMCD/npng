import SwiftUI

struct WatchContentView: View {
    @StateObject private var session = WCSessionManager.shared

    var body: some View {
        VStack {
            if session.playerNumber != "대기 중..." {
                // ✅ 플레이어 번호가 설정됐으면 게임 시작
                BombPartyWatchView()
            } else {
                // ✅ 게임 시작 전 - 네가 만든 예쁜 대기 화면 그대로
                VStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.purple)

                    Text("Play Wrist")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.purple.opacity(0.2))
            }
        }
    }
}
