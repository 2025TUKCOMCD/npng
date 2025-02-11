import SwiftUI
import WatchKit
import Foundation
import CoreMotion // 만보기 기능 추가

// ✅ 심박수 측정 클래스 (HeartRateMonitor)
class HeartRateMonitor: ObservableObject {
    private var timer: Timer?

    // @Published: SwiftUI와 연동될 데이터
    @Published var simulatedHeartRate: Double = 0

    init() {
        startFakeHeartRateMonitoring()
    }

    // 5초마다 랜덤한 심박수 생성
    func startFakeHeartRateMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.simulateHeartRate()
        }
    }

    // 랜덤 심박수 생성 및 진동 실행
    func simulateHeartRate() {
        simulatedHeartRate = Double.random(in: 90...120) // 90~120 사이 랜덤 값
        print("💓 테스트 심박수: \(simulatedHeartRate) BPM")

        if simulatedHeartRate >= 110 {
            triggerHapticFeedback()
        }
    }

    // 진동 실행 (watchOS 기본 햅틱 사용)
    func triggerHapticFeedback() {
        WKInterfaceDevice.current().play(.notification)
        print("🔔 진동 실행됨! 심박수가 110 이상입니다.")
    }
}

// ✅ 숫자 맞추기 게임 (PlayerNumberManager)
class PlayerNumberManager: ObservableObject {
    @Published var assignedNumber: Int = 0 // 현재 플레이어에게 할당된 번호

    func assignRandomNumber(maxPlayers: Int = 8) {
        // 1~8까지의 랜덤 번호 생성
        assignedNumber = Int.random(in: 1...maxPlayers)
        print("🔢 할당된 번호: \(assignedNumber)")
    }
}

// ✅ 만보기 기능 (PedometerManager)
class PedometerManager: ObservableObject {
    private let pedometer = CMPedometer()
    @Published var stepCount: Int = 0

    func startPedometerUpdates() {
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { data, error in
                DispatchQueue.main.async {
                    if let stepData = data {
                        self.stepCount = stepData.numberOfSteps.intValue
                    }
                }
            }
        }
    }
}

// ✅ 심박수 측정 화면 (HeartRateView)
struct HeartRateView: View {
    @StateObject private var heartRateMonitor = HeartRateMonitor()

    var body: some View {
        VStack {
            Text("📊 현재 심박수")
                .font(.headline)

            Text("\(Int(heartRateMonitor.simulatedHeartRate)) BPM")
                .font(.largeTitle)
                .foregroundColor(heartRateMonitor.simulatedHeartRate >= 110 ? .red : .green)

            Spacer()

            if heartRateMonitor.simulatedHeartRate >= 110 {
                Text("미션 완료!!")
                    .foregroundColor(.red)
            } else {
                Text("미션 실패!!")
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding()
    }
}

// ✅ 숫자 맞추기 게임 화면 (WatchNumberGameView)
struct WatchNumberGameView: View {
    @StateObject private var playerManager = PlayerNumberManager()

    var body: some View {
        VStack {
            Text("🎮 랜덤 숫자 게임")
                .font(.headline)

            Text(playerManager.assignedNumber == 1 ? "💣 폭탄" : "당신의 번호: \(playerManager.assignedNumber)")
                .font(.largeTitle)
                .foregroundColor(playerManager.assignedNumber == 1 ? .red : .blue)

            Spacer()

            Button(action: {
                playerManager.assignRandomNumber()
            }) {
                Text("랜덤 번호 받기")
                    .font(.title2)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            playerManager.assignRandomNumber()
        }
    }
}

// ✅ 만보기 화면 (PedometerView)
struct PedometerView: View {
    @StateObject private var pedometerManager = PedometerManager()

    var body: some View {
        VStack {
            Text("🚶 만보기")
                .font(.headline)

            Text("\(pedometerManager.stepCount) 걸음")
                .font(.largeTitle)
                .foregroundColor(pedometerManager.stepCount >= 200 ? .green : .blue)

            Spacer()

            if pedometerManager.stepCount >= 200 {
                Text("🎉 200보 이상 걸었습니다!")
                    .foregroundColor(.green)
                    .font(.title2)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            pedometerManager.startPedometerUpdates()
        }
    }
}

// ✅ 메인 화면 (WatchContentView)
struct WatchContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("⌚️ Apple Watch 앱")
                    .font(.title)

                Spacer()

                NavigationLink(destination: HeartRateView()) {
                    Text("💓 심박수 측정기")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()

                NavigationLink(destination: WatchNumberGameView()) {
                    Text("🎲 숫자 맞추기")
                        .font(.title2)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()

                NavigationLink(destination: PedometerView()) {
                    Text("🚶 만보기")
                        .font(.title2)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
        }
    }
}

// ✅ 앱 진입점 (Play_Wrist_Watch_Watch_AppApp)
