import SwiftUI

struct PatternMemoryGameView: View {
    var onSuccess: () -> Void

    private let icons = ["⬆️", "⬇️", "⬅️", "➡️"]
    @State private var pattern: [String] = []
    @State private var showingIndex = 0
    @State private var showingIcon: String? = nil
    @State private var userInput: [String] = []
    @State private var gameStarted = false
    @State private var gameOver = false
    @State private var resultText = "패턴을 시작하세요"

    var body: some View {
        VStack(spacing: 10) {
            Text("🧠 패턴 기억 미션")
                .font(.headline)

            Text(resultText)
                .font(.footnote)
                .foregroundColor(gameOver ? .red : .primary)

            // 🔁 현재 보여주는 패턴 아이콘 (애니메이션 중)
            if let icon = showingIcon {
                Text(icon)
                    .font(.largeTitle)
                    .padding()
            }

            // ✅ 사용자 입력한 아이콘 목록 표시
            if gameStarted && showingIcon == nil && !userInput.isEmpty {
                Text(userInput.joined(separator: " "))
                    .font(.title3)
                    .padding(.bottom, 4)
            }

            // 👆 입력 버튼
            HStack(spacing: 6) {
                ForEach(icons, id: \.self) { icon in
                    Button(action: {
                        handleInput(icon)
                    }) {
                        Text(icon)
                            .frame(width: 36, height: 36)
                    }
                    .disabled(!gameStarted || showingIcon != nil)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            if !gameStarted {
                Button("시작") {
                    startGame()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    // MARK: - 게임 시작

    func startGame() {
        pattern = (0..<7).map { _ in icons.randomElement()! }
        showingIndex = 0
        userInput = []
        gameOver = false
        gameStarted = true
        resultText = "패턴을 외우세요"
        showPatternStep()
    }

    // MARK: - 패턴 보여주기

    func showPatternStep() {
        guard showingIndex < pattern.count else {
            showingIcon = nil
            resultText = "입력하세요"
            return
        }

        showingIcon = pattern[showingIndex]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showingIcon = nil
            showingIndex += 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showPatternStep()
            }
        }
    }

    // MARK: - 입력 처리

    func handleInput(_ icon: String) {
        userInput.append(icon)

        let idx = userInput.count - 1
        if userInput[idx] != pattern[idx] {
            resultText = "❌ 틀렸어요!"
            gameOver = true
            gameStarted = false
            return
        }

        if userInput.count == pattern.count {
            resultText = "🎉 성공!"
            gameStarted = false
            onSuccess()
        }
    }
}
