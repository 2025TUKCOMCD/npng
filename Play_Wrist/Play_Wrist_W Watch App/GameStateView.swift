import SwiftUI

struct GameStateView: View {
    @ObservedObject var session = WCSessionManager.shared

    var body: some View {
        VStack(spacing: 10) {
            Text("🎮 게임 시작!")
                .font(.headline)
                .foregroundColor(.green)

            Text("당신은 \(session.playerName)")
                .font(.title2)
                .fontWeight(.bold)

            Text("상태: \(session.status)")
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
