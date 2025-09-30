import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit

// ✅ 앱 진입점
struct ContentView: View {
    @StateObject private var viewModel = AppleSignInViewModel()
    @StateObject private var roomViewModel = RoomViewModel()
    
    var body: some View {
        NavigationView {
            if viewModel.isSignedIn {
                MainView(viewModel: viewModel, userName: viewModel.userName ?? "사용자")
                    .environmentObject(viewModel)
                    .environmentObject(roomViewModel)
            } else {
                LandingView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.checkAuthState()
            _ = PhoneWatchConnector.shared // ✅ iPhone ↔ Watch 연결
        }
    }
}
// ✅ Apple 로그인 및 Firebase 연동 ViewModel
class AppleSignInViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate {

    @Published var isSignedIn = false
    @Published var userID: String?
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var idToken: String? = nil

    @Published var winCount: Int = 0
    @Published var loseCount: Int = 0

    var winRate: Double {
        let total = winCount + loseCount
        return total == 0 ? 0 : (Double(winCount) / Double(total) * 100)
    }

    func recordWin() { winCount += 1 }
    func recordLose() { loseCount += 1 }

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
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8)
            else { return }

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

                guard let user = Auth.auth().currentUser else { return }

                // ✅ ID 토큰 요청
                user.getIDTokenForcingRefresh(true) { token, error in
                    if let error = error {
                        print("❌ 토큰 요청 실패: \(error.localizedDescription)")
                        return
                    }

                    DispatchQueue.main.async {
                        self.isSignedIn = true
                        self.userID = user.uid
                        self.userEmail = user.email
                        self.idToken = token

                        if let fullName = appleIDCredential.fullName {
                            let name = "\(fullName.familyName ?? "")\(fullName.givenName ?? "")"
                            if !name.isEmpty {
                                self.userName = name
                                self.updateUserNameInFirebase(name: name)
                            } else {
                                self.userName = user.displayName ?? user.email
                            }
                        } else {
                            self.userName = user.displayName ?? user.email
                        }

                        print("✅ 로그인 성공: \(self.userName ?? "이름 없음")")
                        print("🔑 토큰: \(token ?? "없음")")
                    }
                }
            }

        case .failure(let error):
            print("❌ Apple 로그인 실패: \(error.localizedDescription)")
        }
    }

    private func updateUserNameInFirebase(name: String) {
        guard let user = Auth.auth().currentUser else { return }

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        changeRequest.commitChanges { error in
            if let error = error {
                print("❌ 이름 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ 이름 저장 완료: \(name)")
            }
        }
    }

    func checkAuthState() {
        guard let user = Auth.auth().currentUser else { return }

        DispatchQueue.main.async {
            self.isSignedIn = true
            self.userID = user.uid
            self.userEmail = user.email
            self.userName = user.displayName ?? user.email
        }

        user.getIDTokenForcingRefresh(true) { token, error in
            if let error = error {
                print("❌ 토큰 갱신 실패: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.idToken = token
                    print("🔁 토큰 갱신 완료")
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isSignedIn = false
                self.userID = nil
                self.userEmail = nil
                self.userName = nil
                self.idToken = nil
                self.winCount = 0
                self.loseCount = 0
            }
        } catch {
            print("❌ 로그아웃 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Apple 로그인 관련 유틸
    #if os(iOS)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first ?? UIWindow()
    }
    #endif

    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var bytes = [UInt8](repeating: 0, count: length)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if result != errSecSuccess { fatalError("Nonce 생성 실패") }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

// iOS-specific conformance
#if os(iOS)
extension AppleSignInViewModel: ASAuthorizationControllerPresentationContextProviding {}
#endif
