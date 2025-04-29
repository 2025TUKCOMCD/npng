import SwiftUI

struct FastTapMissionView: View {
    @State private var tapCount = 0
    @State private var startTime: Date? = nil
    @State private var resultText = ""
    var onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("🔫 빠르게 눌러라!")
                .font(.headline)

            Text("지금 탭 수: \(tapCount)")
                .font(.title2)
                .bold()

            Text(resultText)
                .foregroundColor(.purple)
                .font(.footnote)

            Spacer()

            Button("탭!") {
                handleTap()
            }
            .frame(maxWidth: 100)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    private func handleTap() {
        let now = Date()

        if startTime == nil {
            startTime = now
            tapCount = 1
        } else if let start = startTime, now.timeIntervalSince(start) <= 1.0 {
            tapCount += 1
        } else {
            resultText = "⏱ 실패! 다시 시도하세요."
            startTime = nil
            tapCount = 0
            return
        }

        if tapCount >= 5 {
            resultText = "🎉 성공!"
            onSuccess()
        }
    }
}
