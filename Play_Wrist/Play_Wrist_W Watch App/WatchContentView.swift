import SwiftUI

struct WatchContentView: View {
    @ObservedObject var session = WCSessionManager.shared

    var body: some View {
        if session.isGameStarted {
            GameStateView()
        } else if session.isPlayerReady {
            PlayerStateView()
        } else {
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
