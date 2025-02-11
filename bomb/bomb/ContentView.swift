import SwiftUI
import AuthenticationServices

// 게임 뷰모델
class GameViewModel: ObservableObject {
    @Published var assignedNumber: Int?
    @Published var hasBomb: Bool = false
    @Published var countdown: Int = 5
    @Published var gameStarted: Bool = false
    var timer: Timer?
    
    // 플레이어 목록 (간단한 예시로 1~3번)
    @Published var players = ["Player 1", "Player 2", "Player 3"]
    @Published var currentPlayerIndex = 0
    
    func startGame() {
        gameStarted = true
        let numbers = ["bomb", "1", "2", "3"]
        if let randomPick = numbers.randomElement() {
            if randomPick == "bomb" {
                hasBomb = true
                assignedNumber = nil
            } else {
                hasBomb = false
                assignedNumber = Int(randomPick)
                startCountdown()
            }
        }
    }
    
    func startCountdown() {
        countdown = 5
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.countdown > 0 {
                self.countdown -= 1
            } else {
                self.timer?.invalidate()
                self.assignBomb()
            }
        }
    }
    
    func assignBomb() {
        hasBomb = true
        assignedNumber = nil
    }
    
    func passBomb() {
        hasBomb = false
        // 폭탄을 넘길 다음 플레이어 설정
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        assignedNumber = Int.random(in: 1...3)
        startCountdown()
    }
}

// ContentView
struct ContentView: View {
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "User"
    @State private var isLoggedIn: Bool = UserDefaults.standard.bool(forKey: "isLoggedIn")
    @State private var currentScreen: Screen = .main
    
    @StateObject var viewModel = GameViewModel()

    enum Screen {
        case main, game
    }
    
    var body: some View {
        NavigationView {
            if isLoggedIn {
                VStack {
                    switch currentScreen {
                    case .main:
                        MainView(userName: $userName, currentScreen: $currentScreen, isLoggedIn: $isLoggedIn)
                    case .game:
                        GameView(viewModel: viewModel)
                    }
                }
            } else {
                SignInView(userName: $userName, isLoggedIn: $isLoggedIn)
            }
        }
    }
}

// SignInView
struct SignInView: View {
    @Binding var userName: String
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        VStack {
            Text("Sign in to Play!")
                .font(.largeTitle)
                .bold()
                .padding()
            
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let authResults):
                    handleAuthResults(authResults)
                case .failure(let error):
                    print("Apple Sign-In Failed: \(error.localizedDescription)")
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(width: 200, height: 45)
            .cornerRadius(10)
        }
    }
    
    func handleAuthResults(_ authResults: ASAuthorization) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            DispatchQueue.main.async {
                if let fullName = appleIDCredential.fullName?.givenName, !fullName.isEmpty {
                    self.userName = fullName
                    UserDefaults.standard.set(fullName, forKey: "userName")
                } else {
                    self.userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
                }
                self.isLoggedIn = true
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
            }
        }
    }
}

// MainView
struct MainView: View {
    @Binding var userName: String
    @Binding var currentScreen: ContentView.Screen
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text("👤 \(userName)") // 사용자 이름 표시
                    .font(.title2)
                    .bold()
                    .padding()
                Spacer()
            }
            Text("Play Fun!")
                .font(.largeTitle)
                .padding()
            Button("게임 시작") {
                currentScreen = .game
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationBarItems(leading: Button("로그아웃") {
            logOut()
        })
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func logOut() {
        // 로그아웃 처리
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userName")
    }
}

// 게임 화면
struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("게임 시작")
                .font(.largeTitle)
                .padding()
            
            if let number = viewModel.assignedNumber {
                Text("배정된 숫자: \(number)")
            } else if viewModel.hasBomb {
                Text("💣 폭탄이 배정됨! 💣")
                    .foregroundColor(.red)
            } else {
                Text("숫자 배정 중...")
            }
            
            if !viewModel.hasBomb {
                Text("폭탄 배정까지: \(viewModel.countdown)초")
                    .foregroundColor(.gray)
            }
            
            if !viewModel.gameStarted {
                Button("게임 시작") {
                    viewModel.startGame()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            if viewModel.hasBomb {
                Text("현재 플레이어: \(viewModel.players[viewModel.currentPlayerIndex])")
                    .font(.title2)
                    .padding()
                
                Button("폭탄 넘기기") {
                    viewModel.passBomb()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

@main
struct BombGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
