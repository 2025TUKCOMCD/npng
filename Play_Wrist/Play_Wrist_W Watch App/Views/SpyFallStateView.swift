import SwiftUI

struct SpyFallStateView: View {
    @ObservedObject private var sessionManager = WCSessionManager.shared

    var body: some View {
        VStack(spacing: 12) {
            // 🔷 타이틀
            Text("🕵️ Spy Fall")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            Spacer()

            // 🧩 역할 표시
            VStack(spacing: 6) {
                Text("당신의 역할은")
                    .font(.footnote)
                    .foregroundColor(.gray)

                if sessionManager.role == "CITIZEN" {
                    Text(sessionManager.citizenRole)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                } else {
                    Text("스파이")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }

            // 🏥 장소 정보 (시민만 표시)
            if sessionManager.role == "CITIZEN" {
                VStack(spacing: 6) {
                    Text("장소 힌트")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    Text(sessionManager.location)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }

            // 👀 스파이 안내문
            if sessionManager.role == "SPY" {
                Text("대화를 듣고 장소를 유추하세요.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .onAppear {
            print("🕵️‍♀️ SpyFallStateView 진입 - 역할: \(sessionManager.role), 장소: \(sessionManager.location), 세부 역할: \(sessionManager.citizenRole)")
        }
    }
}
