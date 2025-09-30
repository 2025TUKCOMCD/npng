import SwiftUI

struct TimingTapMissionView: View {
    @State private var startTime: Date? = nil
    @State private var resultText = ""
    @State private var timerStarted = false
    var onSuccess: () -> Void

    let targetTime: TimeInterval = 3.0
    let allowedRange: ClosedRange<TimeInterval> = 2.5...3.5

    var body: some View {
        VStack(spacing: 6) {
            Text("⏱️ 정확히 3초에 누르세요\n(오차범위 ±0.5초)")
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.purple)

            if !resultText.isEmpty {
                Text(resultText)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer(minLength: 16)

            if !timerStarted {
                Button("시작") {
                    startTime = Date()
                    timerStarted = true
                    resultText = "3초가 지난 후 눌러보세요!"
                }
                .frame(width: 75, height: 30)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("지금 터치!") {
                    evaluateTiming()
                }
                .frame(width: 90, height: 30)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            Spacer(minLength: 6)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private func evaluateTiming() {
        guard let start = startTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        resultText = allowedRange.contains(elapsed)
            ? "🎯 성공! \(String(format: "%.2f", elapsed))초"
            : "❌ 실패! \(String(format: "%.2f", elapsed))초"

        if allowedRange.contains(elapsed) { onSuccess() }
        timerStarted = false
    }
}
