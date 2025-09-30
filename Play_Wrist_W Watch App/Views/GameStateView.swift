import SwiftUI

struct GameStateView: View {
    @StateObject private var session = WCSessionManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("게임 상태")
                .font(.headline)

            Text("내 번호: \(session.playerNumber)")
                .font(.title2)
                .bold()

            Text("폭탄 보유: \(session.hasBomb ? "O" : "X")")
                .font(.title3)
                .foregroundColor(session.hasBomb ? .red : .green)
                .bold()
        }
        .padding()
    }
}
