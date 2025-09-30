import SwiftUI

struct SpyFallWatchView: View {
    @ObservedObject private var sessionManager = WCSessionManager.shared

    var body: some View {
        VStack(spacing: 12) {
            Text("🕵️ Spy Fall")
                .font(.headline)
                .foregroundColor(.purple)

            Spacer()

            Text("당신의 역할은")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text(sessionManager.role)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(sessionManager.role == "SPY" ? .red : .green)

            if sessionManager.role == "CITIZEN" {
                Text("장소 힌트: \(sessionManager.location)")
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            print("👀 SpyFallWatchView loaded. Current role: \(sessionManager.role)")
        }
    }
}
