import SwiftUI

struct FastTapMissionView: View {
    @State private var tapCount = 0
    @State private var startTime: Date? = nil
    @State private var timerRunning = false
    @State private var resultText = ""
    var onSuccess: () -> Void

    let maxTime: TimeInterval = 5.0
    let requiredTaps: Int = 40

    var body: some View {
        VStack(spacing: 6) {
            // 미션 안내
            Text("🖐️ 5초 안에 \(requiredTaps)번 누르세요")
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.purple)
                .padding(.horizontal, 4)

            // 현재 탭 수
            Text("현재 탭 수: \(tapCount)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)

            // 결과 텍스트
            if !resultText.isEmpty {
                Text(resultText)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 16) // ✅ 버튼 전 여백 약간 추가

            // ✅ 탭 버튼 (사이즈 작게 수정)
            Button("탭!") {
                handleTap()
            }
            .frame(width: 75, height: 30) // ✅ 버튼 더 작게
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)

            Spacer(minLength: 8) // ✅ 하단 여백 확보
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
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
