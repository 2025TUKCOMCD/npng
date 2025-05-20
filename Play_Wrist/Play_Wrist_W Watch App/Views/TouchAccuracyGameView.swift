import SwiftUI

struct TouchAccuracyGameView: View {
    var onSuccess: () -> Void

    @State private var targetPosition: CGPoint = .zero
    @State private var resultText = "시작을 누르세요"
    @State private var gameStarted = false
    @State private var isSuccess = false
    @State private var hitCount = 0
    @State private var timerExpired = false
    @State private var containerSize: CGSize = .zero

    let targetRadius: CGFloat = 20
    let tolerance: CGFloat = 20
    let requiredHits = 7
    let timeLimit: TimeInterval = 5.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .onAppear {
                        containerSize = geometry.size
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                if gameStarted {
                                    evaluateTouch(at: value.location)
                                }
                            }
                    )

                if gameStarted {
                    Circle()
                        .fill(Color.red)
                        .frame(width: targetRadius, height: targetRadius)
                        .position(targetPosition)
                }

                VStack(spacing: 8) {
                    Text(resultText)
                        .font(.footnote)
                        .foregroundColor(isSuccess ? .green : .black)

                    if !gameStarted {
                        Button("시작") {
                            containerSize = geometry.size // 다시 측정 보장
                            startGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.top, 8)
            }
            .edgesIgnoringSafeArea(.all)
        }
    }

    // MARK: - Start Game

    func startGame() {
        hitCount = 0
        timerExpired = false
        gameStarted = true
        isSuccess = false
        resultText = "표적 7번 터치하세요!"
        showNewTarget()

        DispatchQueue.main.asyncAfter(deadline: .now() + timeLimit) {
            if !gameStarted { return }
            timerExpired = true

            if hitCount >= requiredHits {
                resultText = "🎉 성공!"
                isSuccess = true
                gameStarted = false
                onSuccess()
            } else {
                resultText = "⏱ 실패! \(hitCount)회 성공"
                isSuccess = false
                gameStarted = false
            }
        }
    }

    func showNewTarget() {
        let padding: CGFloat = targetRadius + 10
        let x = CGFloat.random(in: padding...(containerSize.width - padding))
        let y = CGFloat.random(in: padding...(containerSize.height - padding))
        targetPosition = CGPoint(x: x, y: y)
    }

    func evaluateTouch(at point: CGPoint) {
        let dx = point.x - targetPosition.x
        let dy = point.y - targetPosition.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance <= tolerance {
            hitCount += 1
            if hitCount >= requiredHits {
                resultText = "🎉 성공!"
                isSuccess = true
                gameStarted = false
                onSuccess()
            } else {
                resultText = "✅ \(hitCount) / \(requiredHits)"
                showNewTarget()
            }
        } else {
            resultText = "❌ 빗맞았어요! 실패"
            isSuccess = false
            gameStarted = false
        }
    }
}
