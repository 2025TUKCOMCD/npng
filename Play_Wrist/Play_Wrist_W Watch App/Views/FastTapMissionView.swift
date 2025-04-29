import SwiftUI

struct FastTapMissionView: View {
    @State private var tapCount = 0
    @State private var startTime: Date? = nil
    @State private var timerRunning = false
    @State private var resultText = ""
    var onSuccess: () -> Void

    let maxTime: TimeInterval = 5.0
    let requiredTaps: Int = 100

    var body: some View {
        VStack(spacing: 14) {
            // ✅ 미션 설명
            Text("🖐️ 5초 안에 화면을 \(requiredTaps)번 누르세요")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.purple)
                .padding(.horizontal, 4)

            // ✅ 현재 카운트
            Text("현재 탭 수: \(tapCount)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)

            // ✅ 미션 결과
            if !resultText.isEmpty {
                Text(resultText)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            // ✅ 탭 버튼
            Button("탭!") {
                handleTap()
            }
            .frame(maxWidth: 90)
            .padding(.vertical, 8)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)

        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .multilineTextAlignment(.center)
    }

    private func handleTap() {
        let now = Date()

        if !timerRunning {
            startTime = now
            timerRunning = true
            tapCount = 1
            resultText = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + maxTime) {
                checkResult()
            }
        } else if let start = startTime, now.timeIntervalSince(start) <= maxTime {
            tapCount += 1
        } else {
            checkResult()
        }
    }

    private func checkResult() {
        timerRunning = false
        if tapCount >= requiredTaps {
            resultText = "🎉 성공! \(tapCount)회"
            onSuccess()
        } else {
            resultText = "❌ 실패! \(tapCount)회"
        }
    }
}
