import SwiftUI
<<<<<<< HEAD
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
                        MainView(userName: $userName, currentScreen: $currentScreen)
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
                .navigationBarHidden(true)
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

struct MainView: View {
    @Binding var userName: String
    @Binding var currentScreen: ContentView.Screen
    
    var body: some View {
        VStack {
            HStack {
                Text("👤 \(userName)")
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

struct InviteCodeSearchView: View {
    @Binding var currentScreen: ContentView.Screen
    @State private var inviteCode: String = ""
    
    var body: some View {
        VStack {
            TextField("초대 코드 입력", text: $inviteCode)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button("검색") {
                // 초대 코드 검색 로직 추가 가능
                print("Searching for room with invite code: \(inviteCode)")
            }
            .buttonStyle(.borderedProminent)
            
            Button("뒤로 가기") {
                currentScreen = .joinRoom
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
=======
import WatchConnectivity

class AppState: ObservableObject {
    @Published var joinedRoomCode: String? = nil

    func updateRoomCode(_ code: String) {
        self.joinedRoomCode = code
    }
}

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Play Wrist")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                NavigationLink(destination: GameView(gameType: "Mafia Game", appState: appState)) {
                    Text("Mafia Game")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: GameView(gameType: "Bomb Party", appState: appState)) {
                    Text("Bomb Party")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .environmentObject(appState)
    }
}

// 공통 게임 뷰 (Mafia Game & Bomb Party)
struct GameView: View {
    var gameType: String
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Text(gameType)
                .font(.title)
                .padding()
            
            NavigationLink(destination: CreateRoomView(gameType: gameType, appState: appState)) {
                Text("방 생성")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            NavigationLink(destination: JoinRoomView(gameType: gameType, appState: appState)) {
                Text("방 참가")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct CreateRoomView: View {
    var gameType: String
    @ObservedObject var appState: AppState
    @State private var inviteCode: String? = nil
    @State private var navigateToRoom = false

    var body: some View {
        VStack(spacing: 20) {
            Text("\(gameType) 방 생성")
                .font(.title)
>>>>>>> 4fb0835 (Local changes before pulling remote)
                .padding()
            
            if let code = inviteCode {
                Text("초대 코드: \(code)")
                    .font(.headline)
<<<<<<< HEAD
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
            Text("재밌는 게임 해요~")
                .font(.title)
                .padding()
            List(players, id: \..self) { player in
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
=======
                    .foregroundColor(.blue)
                    .padding()
                
                NavigationLink(destination: RoomView(gameType: gameType, roomCode: code), isActive: $navigateToRoom) {
                    EmptyView()
                }
                
                Button("방 생성 완료") {
                    appState.updateRoomCode(code)
                    navigateToRoom = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Button(action: generateInviteCode) {
                    Text("방 생성하기")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding()
    }

    func generateInviteCode() {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        inviteCode = String((0..<8).map { _ in characters.randomElement()! })
    }
}

struct JoinRoomView: View {
    var gameType: String
    @ObservedObject var appState: AppState
    @State private var inputCode: String = ""
    @State private var navigateToRoom = false

    var body: some View {
        VStack(spacing: 20) {
            Text("\(gameType) 방 참가")
                .font(.title)
                .padding()
            
            TextField("초대 코드를 입력하세요", text: $inputCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            NavigationLink(destination: RoomView(gameType: gameType, roomCode: inputCode), isActive: $navigateToRoom) {
                EmptyView()
            }
            
            Button("참가하기") {
                appState.updateRoomCode(inputCode)
                navigateToRoom = true
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
    }
}

struct RoomView: View {
    var gameType: String
    var roomCode: String

    var body: some View {
        VStack(spacing: 20) {
            Text("\(gameType) 방에 입장했습니다!")
                .font(.title)
                .padding()
            
            Text("방 코드: \(roomCode)")
                .font(.headline)
                .foregroundColor(.blue)
            
            Spacer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
>>>>>>> 4fb0835 (Local changes before pulling remote)
    }
}
