import SwiftUI
import CoreMotion

struct ShakeMissionView: View {
    @State private var shakeCount = 0
    @State private var resultText = ""
    var onSuccess: () -> Void

    private let motionManager = CMMotionManager()
    private let threshold = 1.2
    private let duration: TimeInterval = 3.0
    private let requiredShakes = 10


    var body: some View {
        VStack(spacing: 6) {
            Text("🤚 손목을 3초 안에 \(requiredShakes)번 이상 흔드세요")
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.purple)

            Text("흔든 횟수: \(shakeCount)")
                .font(.system(size: 14, weight: .bold))

            if !resultText.isEmpty {
                Text(resultText)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer(minLength: 16)

            Button("시작") {
                startShakeDetection()
            }
            .frame(width: 80, height: 30)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)

            Spacer(minLength: 6)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private func startShakeDetection() {
        shakeCount = 0
        resultText = "흔들기 시작!"

        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { data, _ in
                if let accel = data?.acceleration {
                    let magnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
                    if magnitude > threshold {
                        shakeCount += 1
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                motionManager.stopAccelerometerUpdates()
                if shakeCount >= requiredShakes {
                    resultText = "🎉 성공! \(shakeCount)회"
                    onSuccess()
                } else {
                    resultText = "❌ 실패. \(shakeCount)회"
                }
            }
        } else {
            resultText = "가속도 센서를 사용할 수 없습니다."
        }
    }
}
