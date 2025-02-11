import SwiftUI
import WatchConnectivity

class AppState: ObservableObject {
    @Published var joinedRoomCode: String? = nil

    func updateRoomCode(_ code: String) {
        self.joinedRoomCode = code
    }
}

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Play Wrist")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                NavigationLink(destination: GameView(gameType: "Mafia Game", appState: appState)) {
                    Text("Mafia Game")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: GameView(gameType: "Bomb Party", appState: appState)) {
                    Text("Bomb Party")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .environmentObject(appState)
    }
}

// 공통 게임 뷰 (Mafia Game & Bomb Party)
struct GameView: View {
    var gameType: String
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Text(gameType)
                .font(.title)
                .padding()
            
            NavigationLink(destination: CreateRoomView(gameType: gameType, appState: appState)) {
                Text("방 생성")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            NavigationLink(destination: JoinRoomView(gameType: gameType, appState: appState)) {
                Text("방 참가")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct CreateRoomView: View {
    var gameType: String
    @ObservedObject var appState: AppState
    @State private var inviteCode: String? = nil
    @State private var navigateToRoom = false

    var body: some View {
        VStack(spacing: 20) {
            Text("\(gameType) 방 생성")
                .font(.title)
                .padding()
            
            if let code = inviteCode {
                Text("초대 코드: \(code)")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                
                NavigationLink(destination: RoomView(gameType: gameType, roomCode: code), isActive: $navigateToRoom) {
                    EmptyView()
                }
                
                Button("방 생성 완료") {
                    appState.updateRoomCode(code)
                    navigateToRoom = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Button(action: generateInviteCode) {
                    Text("방 생성하기")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding()
    }

    func generateInviteCode() {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        inviteCode = String((0..<8).map { _ in characters.randomElement()! })
    }
}

struct JoinRoomView: View {
    var gameType: String
    @ObservedObject var appState: AppState
    @State private var inputCode: String = ""
    @State private var navigateToRoom = false

    var body: some View {
        VStack(spacing: 20) {
            Text("\(gameType) 방 참가")
                .font(.title)
                .padding()
            
            TextField("초대 코드를 입력하세요", text: $inputCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            NavigationLink(destination: RoomView(gameType: gameType, roomCode: inputCode), isActive: $navigateToRoom) {
                EmptyView()
            }
            
            Button("참가하기") {
                appState.updateRoomCode(inputCode)
                navigateToRoom = true
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
    }
}

struct RoomView: View {
    var gameType: String
    var roomCode: String

    var body: some View {
        VStack(spacing: 20) {
            Text("\(gameType) 방에 입장했습니다!")
                .font(.title)
                .padding()
            
            Text("방 코드: \(roomCode)")
                .font(.headline)
                .foregroundColor(.blue)
            
            Spacer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
