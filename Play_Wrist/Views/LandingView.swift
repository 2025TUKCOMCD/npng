import SwiftUI
import AuthenticationServices

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
