import SwiftUI
import WatchKit

struct HapticReactionGameView: View {
    var onSuccess: () -> Void
    @State private var statusText = "시작을 누르세요"
    @State private var gameStarted = false
    @State private var vibrationTriggered = false
    @State private var startTime: Date?
    @State private var reactionTime: Double?
    @State private var showResult = false

    // 성공 판정 기준 시간 (초)
    let maxReactionTime: Double = 0.7

    var body: some View {
        VStack(spacing: 12) {
            Text(statusText)
                .font(.headline)
                .multilineTextAlignment(.center)

            if let reaction = reactionTime {
                Text(String(format: "⏱ %.3f초", reaction))
                    .foregroundColor(.blue)
            }

            Button(action: handleButtonPress) {
                Text(gameStarted ? "눌러!" : "시작")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    func handleButtonPress() {
        if !gameStarted {
            startGame()
        } else {
            if vibrationTriggered, let start = startTime {
                let elapsed = Date().timeIntervalSince(start)
                reactionTime = elapsed
                if elapsed <= maxReactionTime {
                    statusText = "🎉 성공! 빠른 반응이에요"
                } else {
                    statusText = "⌛ 너무 늦었어요!"
                }
                resetGame()
            } else {
                statusText = "❌ 너무 빨라요!"
                reactionTime = nil
                resetGame()
            }
        }
    }

    func startGame() {
        statusText = "진동이 오면 눌러요!"
        gameStarted = true
        vibrationTriggered = false
        reactionTime = nil

        let delay = Double.random(in: 2.0...5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            WKInterfaceDevice.current().play(.notification)
            vibrationTriggered = true
            startTime = Date()
            statusText = "지금 눌러요!"
        }
    }

    func resetGame() {
        gameStarted = false
        vibrationTriggered = false
        startTime = nil
    }
}
