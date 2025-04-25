import SwiftUI

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
