import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: AppleSignInViewModel
    var userName: String

    @State private var showProfile = false
    @State private var goToGameSelect = false
    @State private var goToRoomList = false

    var body: some View {
        VStack(spacing: 0) {
            // 🔹 상단 바 (정렬 보정 완료)
            HStack {
                Text("\(userName)님")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(height: 44)

                Spacer()

                Text("Play Wrist")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(height: 44)

                Spacer()

                Button(action: {
                    viewModel.signOut()
                }) {
                    Image(systemName: "power")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(height: 44)
                }
            }
            .padding(.horizontal)
            .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 20)
            .padding(.bottom, 10)
            .background(Color.purple)
            .ignoresSafeArea(edges: .top)

            Spacer()

            // 🔸 중앙 콘텐츠
            Text("Play Fun!!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            VStack(spacing: 20) {
                // 방 만들기
                NavigationLink(destination: GameSelectView().environmentObject(viewModel), isActive: $goToGameSelect) {
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

                // 방 찾기
                NavigationLink(destination: RoomListView().environmentObject(viewModel), isActive: $goToRoomList) {
                    EmptyView()
                }

                Button(action: {
                    goToRoomList = true
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

            // 🔻 하단 탭바
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
        .background(Color.purple.opacity(0.1).ignoresSafeArea())
    }
}
