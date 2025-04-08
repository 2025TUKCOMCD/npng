import SwiftUI
import CryptoKit
import AuthenticationServices
import FirebaseAuth

struct ContentView: View {
    @StateObject private var viewModel = AppleSignInViewModel()
    
    var body: some View {
        NavigationView {
            if viewModel.isSignedIn {
                MainView(viewModel: viewModel, userName: viewModel.userName ?? "사용자")
                    .environmentObject(viewModel)
            } else {
                LandingView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.checkAuthState()
        }
    }
}

// ✅ 로그인 전 화면
struct LandingView: View {
    @ObservedObject var viewModel: AppleSignInViewModel

    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "play.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.purple)
                .padding(.bottom, 10)
            
            Text("Play Wrist")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            Spacer()
            
            SignInWithAppleButton(
                onRequest: { request in
                    viewModel.startSignInWithAppleFlow(request: request)
                },
                onCompletion: { result in
                    viewModel.handleSignInResult(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            
            Spacer()
        }
        .background(Color.purple.opacity(0.2).edgesIgnoringSafeArea(.all))
    }
}

// ✅ 로그인 후 메인 화면
import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: AppleSignInViewModel
    var userName: String

    @State private var showProfile = false
    @State private var goToGameSelect = false

    var body: some View {
        VStack {
            // 🔹 상단 바
            HStack {
                Text("\(userName)님")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.leading, 10)

                Spacer()

                Text("Play Wrist")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    viewModel.signOut()
                }) {
                    Image(systemName: "power")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.trailing, 10)
                }
            }
            .padding()
            .background(Color.purple)

            Spacer()

            // 🔸 중앙 텍스트
            Text("Play Fun!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            VStack(spacing: 20) {
                // ✅ NavigationLink → GameSelectView 이동
                NavigationLink(destination: GameSelectView().environmentObject(viewModel), isActive: $goToGameSelect){
                    EmptyView()
                }

                Button(action: {
                    goToGameSelect = true
                }) {
                    Text("방 만들기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    // 추후 방 찾기 기능 연결
                }) {
                    Text("방 찾기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            // 🔹 하단 탭바
            HStack {
                Spacer()
                Button(action: {}) {
                    Image(systemName: "house.fill")
                        .font(.title)
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.title)
                }
                Spacer()
                Button(action: {
                    showProfile = true
                }) {
                    Image(systemName: "book.fill")
                        .font(.title)
                }
                .background(
                    NavigationLink(destination: MyProfileView(viewModel: viewModel), isActive: $showProfile) {
                        EmptyView()
                    }
                    .hidden()
                )
                Spacer()
                Button(action: {}) {
                    Image(systemName: "gearshape.fill")
                        .font(.title)
                }
                Spacer()
            }
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
        }
        .background(Color.purple.opacity(0.1).edgesIgnoringSafeArea(.all))
    }
}
struct MyProfileView: View {
    @ObservedObject var viewModel: AppleSignInViewModel

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.purple)
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "person.fill")
                    Text("이름: \(viewModel.userName ?? "알 수 없음")")
                }

                HStack {
                    Image(systemName: "trophy.fill")
                    Text("플레이 통계")
                }

                HStack {
                    Text("🏆 승: \(viewModel.winCount)")
                    Text("❌ 패: \(viewModel.loseCount)")
                    Text("📊 승률: \(String(format: "%.1f%%", viewModel.winRate))")
                }
            }
            .font(.body)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            // ✅ 테스트용 승/패 버튼
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.recordWin()
                }) {
                    Text("승리 추가")
                        .padding()
                        .frame(width: 120)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    viewModel.recordLose()
                }) {
                    Text("패배 추가")
                        .padding()
                        .frame(width: 120)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            Spacer()

            // 로그아웃 버튼
            Button(action: {
                viewModel.signOut()
            }) {
                Text("로그아웃")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("내 정보")
        .background(Color.white.ignoresSafeArea())
    }
}

struct GameSelectView: View {
    @EnvironmentObject var viewModel: AppleSignInViewModel
    @State private var selectedGame = ""
    @State private var navigateToRoomSetup = false

    var body: some View {
        VStack(spacing: 30) {
            Text("게임 선택")
                .font(.title)

            Button(action: {
                selectedGame = "Bomb Party"
                navigateToRoomSetup = true
            }) {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("Bomb Party")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.2))
                .cornerRadius(12)
            }

            Button(action: {
                selectedGame = "Mafia Game"
                navigateToRoomSetup = true
            }) {
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("Mafia Game")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.2))
                .cornerRadius(12)
            }

            NavigationLink(
                destination: RoomSetupView(selectedGame: selectedGame).environmentObject(viewModel),
                isActive: $navigateToRoomSetup
            ) {
                EmptyView()
            }
        }
        .padding()
        .navigationTitle("게임 선택")
    }
}

struct RoomSetupView: View {
    var selectedGame: String
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @StateObject private var roomViewModel = RoomViewModel()

    @State private var roomTitle = ""
    @State private var password = ""
    @State private var playerCount = "4"
    @State private var navigateToLobby = false

    var body: some View {
        VStack(spacing: 20) {
            TextField("방 제목", text: $roomTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("비밀번호", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("인원 수", text: $playerCount)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                let host = authViewModel.userName ?? "user1"
                roomViewModel.createRoom(
                    title: roomTitle,
                    game: selectedGame,
                    password: password,
                    maxPlayers: Int(playerCount) ?? 4,
                    hostName: host
                )
                navigateToLobby = true
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)
            }

            NavigationLink(
                destination: GameLobbyView(room: roomViewModel.room ?? Room(title: "", game: "", password: "", maxPlayers: 4, hostName: "", players: [])).environmentObject(authViewModel),
                isActive: $navigateToLobby
            ) {
                EmptyView()
            }
        }
        .padding()
        .navigationTitle("방 정보 입력")
    }
}

struct GameLobbyView: View {
    let room: Room
    @EnvironmentObject var authViewModel: AppleSignInViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text(room.title)
                .font(.title2)
                .padding(.top)
            Text(room.game)
                .foregroundColor(.blue)
                .padding(.bottom)

            Text("방장: \(room.hostName)")
                .font(.headline)
                .padding(.bottom, 10)

            let fullPlayers = room.players + Array(repeating: "", count: max(0, room.maxPlayers - room.players.count))
            let mid = fullPlayers.count / 2
            let left = fullPlayers.prefix(mid)
            let right = fullPlayers.suffix(from: mid)

            HStack {
                VStack(alignment: .leading) {
                    ForEach(Array(left.enumerated()), id: \.offset) { _, player in
                        Text(player.isEmpty ? "대기 중..." : player).padding()
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    ForEach(Array(right.enumerated()), id: \.offset) { _, player in
                        Text(player.isEmpty ? "대기 중..." : player).padding()
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            Button("Start") {
                print("게임 시작")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .navigationTitle("대기방")
    }
}

struct Room {
    let title: String
    let game: String
    let password: String
    let maxPlayers: Int
    let hostName: String
    var players: [String]
}

class RoomViewModel: ObservableObject {
    @Published var room: Room?

    func createRoom(title: String, game: String, password: String, maxPlayers: Int, hostName: String) {
        room = Room(
            title: title,
            game: game,
            password: password,
            maxPlayers: maxPlayers,
            hostName: hostName,
            players: [hostName]
        )
    }
}

// ✅ Apple 로그인 & Firebase 관리 뷰 모델
class AppleSignInViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @Published var isSignedIn = false
    @Published var userID: String?
    @Published var userEmail: String?
    @Published var userName: String?
    
    @Published var winCount: Int = 0
        @Published var loseCount: Int = 0
        
        // ✅ 승률 계산
        var winRate: Double {
            let total = winCount + loseCount
            return total == 0 ? 0 : (Double(winCount) / Double(total) * 100)
        }

        // ✅ 수동 기록 함수
        func recordWin() {
            winCount += 1
        }

        func recordLose() {
            loseCount += 1
        }

        // 로그아웃 시 초기화
        func signOut() {
            do {
                try Auth.auth().signOut()
                DispatchQueue.main.async {
                    self.isSignedIn = false
                    self.userID = nil
                    self.userEmail = nil
                    self.userName = nil
                    self.winCount = 0 // 승패 초기화
                    self.loseCount = 0
                }
            } catch {
                print("❌ 로그아웃 실패: \(error.localizedDescription)")
            }
        }
    
    fileprivate var currentNonce: String?
    
    func startSignInWithAppleFlow(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    func handleSignInResult(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else { return }
                guard let appleIDToken = appleIDCredential.identityToken else { return }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }

                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )

                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("❌ Firebase 로그인 실패: \(error.localizedDescription)")
                        return
                    }

                    if let user = Auth.auth().currentUser {
                        DispatchQueue.main.async {
                            self.isSignedIn = true
                            self.userID = user.uid
                            self.userEmail = user.email

                            if let fullName = appleIDCredential.fullName {
                                let name = "\(fullName.familyName ?? "")\(fullName.givenName ?? "")"
                                if !name.isEmpty {
                                    self.userName = name
                                    self.updateUserNameInFirebase(name: name)
                                }
                            } else {
                                self.userName = user.displayName ?? user.email
                            }

                            // ✅ Firebase 인증 성공 로그 출력!
                            print("✅ Firebase 인증 성공! 🎉")
                            print("🆔 UID: \(user.uid)")
                            print("📧 이메일: \(user.email ?? "이메일 없음")")
                            print("🙍‍♂️ 이름: \(self.userName ?? "이름 없음")")
                        }
                    }
                }
            }
        case .failure(let error):
            print("Apple 로그인 오류: \(error.localizedDescription)")
        }
    }
    
    private func updateUserNameInFirebase(name: String) {
        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges { error in
                if let error = error {
                    print("❌ Firebase에 사용자 이름 저장 실패: \(error.localizedDescription)")
                } else {
                    print("✅ Firebase에 사용자 이름 저장 완료: \(name)")
                }
            }
        }
    }
    
    
    func checkAuthState() {
        if let user = Auth.auth().currentUser {
            DispatchQueue.main.async {
                self.isSignedIn = true
                self.userID = user.uid
                self.userEmail = user.email
                self.userName = user.displayName ?? user.email
            }
        }
    }
    
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first ?? UIWindow()
    }
    
    // ✅ Apple 로그인용 난수(Nonce) 생성
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("난수 생성 실패: SecRandomCopyBytes 오류 코드 \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    // ✅ SHA256 해싱 (Apple 로그인 보안용)
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}
 
