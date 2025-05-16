import SwiftUI
import WatchKit

struct TouchAccuracyGameView: View {
    var onSuccess: () -> Void
    @State private var targetPosition: CGPoint = .zero
    @State private var userTapPosition: CGPoint? = nil
    @State private var resultText: String = "시작을 누르세요"
    @State private var gameStarted = false
    @State private var isSuccess = false

    // 목표 터치 반경 허용 범위 (픽셀)
    let targetRadius: CGFloat = 30
    let tolerance: CGFloat = 25

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 터치 인식
                Color.white
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                if gameStarted {
                                    userTapPosition = value.location
                                    evaluateTouch()
                                }
                            }
                    )

                // 타겟 원
                if gameStarted {
                    Circle()
                        .fill(Color.red)
                        .frame(width: targetRadius, height: targetRadius)
                        .position(targetPosition)
                }

                // 결과 표시
                VStack {
                    Spacer()
                    Text(resultText)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isSuccess ? .green : .black)
                    Button("시작") {
                        startGame(in: geometry.size)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }

    func startGame(in size: CGSize) {
        // 화면 내 랜덤 위치 설정 (상하단 여백 고려)
        let padding: CGFloat = 40
        let x = CGFloat.random(in: padding...(size.width - padding))
        let y = CGFloat.random(in: padding...(size.height - padding))
        targetPosition = CGPoint(x: x, y: y)
        userTapPosition = nil
        resultText = "표적을 눌러보세요!"
        gameStarted = true
        isSuccess = false
    }

    func evaluateTouch() {
        guard let userPos = userTapPosition else { return }

        let dx = userPos.x - targetPosition.x
        let dy = userPos.y - targetPosition.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance <= tolerance {
            resultText = "🎯 정확해요!"
            isSuccess = true
        } else {
            resultText = "😵 빗맞았어요!\n거리: \(Int(distance))"
            isSuccess = false
        }

        gameStarted = false
    }
}
