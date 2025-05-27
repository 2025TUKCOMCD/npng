import SwiftUI

struct WatchContentView: View {
    @ObservedObject private var session = WCSessionManager.shared

    var body: some View {
        VStack {
            switch session.currentGame {
            case "BombParty":
                BombPartyWatchView()

            case "SpyFall":
                SpyFallStateView()

            default:
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
