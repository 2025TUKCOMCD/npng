import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "User"
    @State private var isLoggedIn: Bool = UserDefaults.standard.bool(forKey: "isLoggedIn")
    @State private var navigateTo: String? = nil  // 화면 전환을 위한 상태

    var body: some View {
        NavigationView {
            if isLoggedIn {
                MainView(userName: userName, navigateTo: $navigateTo)
            } else {
                SignInView(userName: $userName, isLoggedIn: $isLoggedIn)
            }
        }
    }
}

// 🚀 Apple 로그인 화면
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
                    UserDefaults.standard.set(fullName, forKey: "userName")  // ✅ 이름 저장
                } else {
                    self.userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
                }
                self.isLoggedIn = true
                UserDefaults.standard.set(true, forKey: "isLoggedIn")  // ✅ 로그인 상태 저장
            }
        }
    }
}

// 🎮 메인 화면 (로그인 후)
struct MainView: View {
    var userName: String
    @Binding var navigateTo: String?

    var body: some View {
        VStack {
            HStack {
                Text("👤 \(userName)")
                    .font(.title2)
                    .bold()
                    .padding()
                Spacer()
            }
            .padding(.leading)

            Spacer()
            Text("Play Fun!")
                .font(.largeTitle)
                .bold()
                .padding()

            Button("방 만들기") {
                navigateTo = "createRoom"
            }
            .buttonStyle(MainButtonStyle())

            Button("방 찾기") {
                navigateTo = "findRoom"
            }
            .buttonStyle(MainButtonStyle())

            Spacer()
        }
        .background(
            NavigationLink(destination: GameSelectionView(), tag: "createRoom", selection: $navigateTo) {
                EmptyView()
            }
            .hidden()
        )
        .background(
            NavigationLink(destination: FindRoomView(), tag: "findRoom", selection: $navigateTo) {
                EmptyView()
            }
            .hidden()
        )
    }
}

// 🎲 게임 선택 화면
struct GameSelectionView: View {
    var body: some View {
        VStack {
            Text("Play Wrist")
                .font(.title)
                .bold()
                .padding()

            GameOptionView(icon: "bomb.fill", title: "Bomb Party", description: "랜덤 미션 폭탄 돌리기 게임")
            GameOptionView(icon: "cross.fill", title: "Mafia Game", description: "마피아 게임을 현실에서!")

            Spacer()
        }
    }
}

// 🎮 방 찾기 화면
struct FindRoomView: View {
    @State private var roomCode: String = ""

    var body: some View {
        VStack {
            Text("Play Wrist")
                .font(.title)
                .bold()
                .padding()

            TextField("Enter the Code", text: $roomCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Join") {
                print("Joining room: \(roomCode)")
            }
            .buttonStyle(MainButtonStyle())

            Spacer()
        }
    }
}

// 🎨 버튼 스타일
struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 200, height: 50)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// 🎲 게임 선택 카드 UI
struct GameOptionView: View {
    var icon: String
    var title: String
    var description: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.largeTitle)
                .padding()
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3)
                    .bold()
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .frame(width: 300, height: 80)
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
        .padding()
    }
}

// 앱 실행
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
