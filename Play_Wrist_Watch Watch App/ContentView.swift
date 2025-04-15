import SwiftUI

struct ContentView: View {
    @StateObject var connector = WatchConnector()

    var body: some View {
        VStack {
            if connector.gameStarted {
                Text("🎮 Play Wrist 시작!")
            } else {
                Text("⌛ 대기 중...")
            }
        }
        .onAppear {
            // 이거 호출되면서 session 초기화됨
            _ = connector
        }
    }
}
