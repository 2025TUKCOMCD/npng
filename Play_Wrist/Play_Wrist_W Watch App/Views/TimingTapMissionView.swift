import SwiftUI

struct TimingTapMissionView: View {
    @State private var startTime: Date? = nil
    @State private var resultText = ""
    @State private var timerStarted = false
    var onSuccess: () -> Void

    // 🔍 미션 조건
    let targetTime: TimeInterval = 3.0
    let allowedRange: ClosedRange<TimeInterval> = 2.5...3.5

    var body: some View {
        VStack(spacing: 14) {
            // ✅ 미션 설명
            Text("⏱️ 정확히 \(Int(targetTime))초를 맞춰 누르세요\n(오차 범위 ±0.5초)")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.purple)
                .padding(.horizontal, 4)

            // ✅ 결과 안내
            if !resultText.isEmpty {
                Text(resultText)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            // ✅ 시작 버튼
            if !timerStarted {
                Button("시작") {
                    startTime = Date()
                    timerStarted = true
                    resultText = "3초가 지난 후 눌러보세요!"
                }
                .frame(maxWidth: 100)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            // ✅ 누르기 버튼
            if timerStarted {
                Button("지금 터치!") {
                    evaluateTiming()
                }
                .frame(maxWidth: 100)
                .padding(.vertical, 8)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .multilineTextAlignment(.center)
    }

    private func evaluateTiming() {
        guard let start = startTime else { return }
        let elapsed = Date().timeIntervalSince(start)

        if allowedRange.contains(elapsed) {
            resultText = "🎯 성공! \(String(format: "%.2f", elapsed))초"
            onSuccess()
        } else {
            resultText = "❌ 실패! \(String(format: "%.2f", elapsed))초"
        }

        timerStarted = false
    }
}
