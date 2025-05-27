import SwiftUI

struct GameSelectView: View {
    @EnvironmentObject var viewModel: AppleSignInViewModel
    @State private var selectedGame = ""
    @State private var navigateToRoomSetup = false

    var body: some View {
        VStack(spacing: 30) {
            Text("게임 선택")
                .font(.title)
                .padding(.top)

            VStack(spacing: 20) {
                // 🔸 Bomb Party 카드
                Button(action: {
                    selectedGame = "Bomb Party"
                    navigateToRoomSetup = true
                }) {
                    HStack(spacing: 15) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: "flame.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.purple)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Bomb Party")
                                .font(.headline)
                                .foregroundColor(.purple)

                            Text("랜덤 미션 폭탄 돌리기 게임")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple, lineWidth: 1)
                    )
                }

                // 🔸 Mafia Game 카드
                Button(action: {
                    selectedGame = "SPY Fall"
                    navigateToRoomSetup = true
                }) {
                    HStack(spacing: 15) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: "person.3.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.purple)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("SPY Fall")
                                .font(.headline)
                                .foregroundColor(.purple)

                            Text("스파이를 찾아라!")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)

            // 👉 다음 화면으로 연결
            NavigationLink(
                destination: RoomSetupView(selectedGame: selectedGame).environmentObject(viewModel),
                isActive: $navigateToRoomSetup
            ) {
                EmptyView()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("게임 선택")
    }
}
