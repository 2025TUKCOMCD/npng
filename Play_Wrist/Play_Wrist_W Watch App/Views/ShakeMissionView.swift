import SwiftUI
import CoreMotion

struct ShakeMissionView: View {
    @State private var shakeCount = 0
    @State private var resultText = ""
    var onSuccess: () -> Void

    private let motionManager = CMMotionManager()
    private let threshold = 1.2
    private let duration: TimeInterval = 3.0

    var body: some View {
        VStack(spacing: 12) {
            Text("🤚 손목을 흔들어라!")
                .font(.headline)

            Text("흔든 횟수: \(shakeCount)")
                .font(.title2)
                .bold()

            Text(resultText)
                .foregroundColor(.purple)
                .font(.footnote)

            Button("시작") {
                startShakeDetection()
            }
            .frame(maxWidth: 100)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    private func startShakeDetection() {
        shakeCount = 0
        resultText = "흔들기 시작!"

        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { data, error in
                if let accel = data?.acceleration {
                    let magnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
                    if magnitude > threshold {
                        shakeCount += 1
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                motionManager.stopAccelerometerUpdates()
                if shakeCount >= 5 {
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
