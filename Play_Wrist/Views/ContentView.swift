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
 
