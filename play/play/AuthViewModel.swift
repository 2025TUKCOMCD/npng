import SwiftUI
import AuthenticationServices
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false  // 로그인 상태
    @Published var userName: String? = nil  // 사용자 이름

    init() {
        checkLoginStatus()
    }

    // ✅ 로그인 상태 감지
    func checkLoginStatus() {
        if let user = Auth.auth().currentUser {
            self.isLoggedIn = true
            self.userName = UserDefaults.standard.string(forKey: "appleUserName") ?? "사용자"
        } else {
            self.isLoggedIn = false
            self.userName = nil
        }
    }

    // ✅ Apple 로그인 & Firebase 인증
    func handleAppleLogin() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    // ✅ 로그아웃
    func logout() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
            self.userName = nil
        } catch {
            print("로그아웃 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - Apple 로그인 Delegate
extension AuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let appleIDToken = appleIDCredential.identityToken,
           let idTokenString = String(data: appleIDToken, encoding: .utf8) {
            
            // ✅ Firebase에 인증 정보 넘기기
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nil)
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase 로그인 실패: \(error.localizedDescription)")
                    return
                }
                
                // ✅ Firebase 로그인 성공 → 사용자 정보 저장
                if let user = result?.user {
                    let fullName = appleIDCredential.fullName
                    let firstName = fullName?.givenName ?? "사용자"
                    UserDefaults.standard.set(firstName, forKey: "appleUserName")
                    
                    DispatchQueue.main.async {
                        self.isLoggedIn = true
                        self.userName = firstName
                    }
                }
            }
        }
    }
}
