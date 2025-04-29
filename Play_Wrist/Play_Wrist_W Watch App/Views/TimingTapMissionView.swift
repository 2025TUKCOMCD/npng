import SwiftUI

struct TimingTapMissionView: View {
    @State private var startTime: Date? = nil
    @State private var resultText = ""
    var onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("⏰ 정확한 타이밍에 터치!")
                .font(.headline)

            Button("시작") {
                startTime = Date()
                resultText = "3.5~4.5초 후에 눌러보세요!"
            }

            Button("지금 터치!") {
                handleTouch()
            }
            .frame(maxWidth: 100)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Text(resultText)
                .foregroundColor(.purple)
                .font(.footnote)
        }
        .padding()
    }

    private func handleTouch() {
        guard let start = startTime else {
            resultText = "먼저 시작 버튼을 눌러야 해요!"
            return
        }

        let elapsed = Date().timeIntervalSince(start)

        if elapsed >= 3.5 && elapsed <= 4.5 {
            resultText = "🎯 정확히 눌렀어요!"
            onSuccess()
        } else {
            resultText = "❌ 실패! \(String(format: "%.2f", elapsed))초"
        }
    }
}
