import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "User"
    @State private var isLoggedIn: Bool = UserDefaults.standard.bool(forKey: "isLoggedIn")
    @State private var currentScreen: Screen = .main
    
    enum Screen {
        case main, gameSelection, joinRoom, createRoom, playerList
    }
    
    var body: some View {
        NavigationView {
            if isLoggedIn {
                VStack {
                    switch currentScreen {
                    case .main:
                        MainView(userName: $userName, currentScreen: $currentScreen, isLoggedIn: $isLoggedIn)
                    case .gameSelection:
                        GameSelectionView(currentScreen: $currentScreen)
                    case .joinRoom:
                        JoinRoomView(currentScreen: $currentScreen)
                    case .createRoom:
                        CreateRoomView(currentScreen: $currentScreen)
                    case .playerList:
                        PlayerListView(currentScreen: $currentScreen)
                    }
                }
                .navigationBarHidden(false) // Navigation bar를 보이게 설정
            } else {
                SignInView(userName: $userName, isLoggedIn: $isLoggedIn)
            }
        }
    }
}

struct SignInView: View {
    @Binding var userName: String
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        VStack {
            Text("Play Wrist~~!")
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
                // fullName에서 firstName을 제대로 받는지 확인
                if let fullName = appleIDCredential.fullName?.givenName, !fullName.isEmpty {
                    self.userName = fullName
                    UserDefaults.standard.set(fullName, forKey: "userName")
                } else {
                    // Apple 계정에 이름이 없다면 이메일을 사용자 이름으로 사용
                    self.userName = appleIDCredential.email ?? "User"
                    UserDefaults.standard.set(self.userName, forKey: "userName")
                }
                self.isLoggedIn = true
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
            }
        }
    }
}

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
            Button("방 만들기") {
                currentScreen = .gameSelection
            }
            .buttonStyle(.borderedProminent)
            Button("방 찾기") {
                currentScreen = .joinRoom
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

struct GameSelectionView: View {
    @Binding var currentScreen: ContentView.Screen
    
    var body: some View {
        VStack {
            Button("Bomb Party") {
                currentScreen = .createRoom
            }
            .buttonStyle(.borderedProminent)
            Button("Mafia Game") {
                currentScreen = .createRoom
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct JoinRoomView: View {
    @Binding var currentScreen: ContentView.Screen
    @State private var roomCode: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter the Code", text: $roomCode)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button("Join") {
                currentScreen = .playerList
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct CreateRoomView: View {
    @Binding var currentScreen: ContentView.Screen
    @State private var roomTitle: String = ""
    @State private var password: String = ""
    @State private var inviteCode: String? = nil
    
    var body: some View {
        VStack {
            TextField("방 제목", text: $roomTitle)
                .textFieldStyle(.roundedBorder)
                .padding()
            SecureField("비밀번호", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            if let code = inviteCode {
                Text("초대 코드: \(code)")
                    .font(.headline)
                    .padding()
            }
            
            Button("코드로 초대하기") {
                inviteCode = generateInviteCode()
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: {
                currentScreen = .playerList
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.largeTitle)
            }
        }
    }
    
    func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}

struct PlayerListView: View {
    @Binding var currentScreen: ContentView.Screen
    let players = ["User 1", "User 2", "User 3", "User 4", "User 5", "User 6", "User 7", "User 8"]
    
    var body: some View {
        VStack {
            Text("Play Wrist~")
                .font(.title)
                .padding()
            List(players, id: \.self) { player in
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text(player)
                    Spacer()
                    if Bool.random() {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button("게임 시작") {
                // 게임 시작 로직 추가 가능
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
