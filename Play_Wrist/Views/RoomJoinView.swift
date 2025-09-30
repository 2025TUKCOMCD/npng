import SwiftUI

struct RoomJoinView: View {
    var room: Room
    @ObservedObject var roomViewModel: RoomViewModel
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var password: String
    @State private var showAlert = false
    @State private var alertMessage = "비밀번호가 틀렸습니다."
    @State private var navigateToLobby = false
    @State private var isLoading = false
    @State private var connectionStatus = "연결 확인 중..."
    
    init(room: Room, roomViewModel: RoomViewModel) {
        self.room = room
        self.roomViewModel = roomViewModel
        self._password = State(initialValue: room.password)
    }

    var body: some View {
        VStack(spacing: 20) {
            // 방 정보
            Text(room.title)
                .font(.title2)
                .bold()

            Text("게임: \(room.game)")
                .foregroundColor(.gray)

            Text("방장: \(room.hostName)")
                .foregroundColor(.gray)
            
            // 연결 상태 표시
            HStack {
                Circle()
                    .fill(isLoading ? .orange : .green)
                    .frame(width: 8, height: 8)
                Text(connectionStatus)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // 비밀번호
            SecureField("비밀번호 입력", text: $password)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

            // 입장 버튼
            Button {
                guard !isLoading else { 
                    print("🚫 [RoomJoinView] 이미 로딩 중이므로 중복 클릭 무시")
                    return 
                }
                
                print("🚪 [RoomJoinView] 입장 버튼 클릭됨")
                print("📋 방 정보: ID=\(room.id), 제목=\(room.title)")
                
                isLoading = true
                let userName = authViewModel.userName ?? "User"
                print("👤 사용자명: \(userName)")

                Task {
                    do {
                        // 연결 상태 업데이트
                        await MainActor.run {
                            connectionStatus = "서버 연결 중..."
                        }
                        
                        print("🔗 [RoomJoinView] WebSocket joinRoom 요청 시작...")
                        print("🔐 [RoomJoinView] 입력된 패스워드: '\(password)'")
                        print("🔐 [RoomJoinView] 방 패스워드: '\(room.password)'")
                        
                        // 먼저 방 목록을 다시 조회해서 최신 상태 확인
                        print("🔄 [RoomJoinView] 최신 방 정보 조회 중...")
                        await WebSocketService.shared.fetchRooms()
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
                        
                        // 최신 방 정보에서 중복 플레이어 체크
                        if let currentRoom = roomViewModel.rooms.first(where: { $0.id == room.id }) {
                            print("📋 [RoomJoinView] 현재 방 정보: ID=\(currentRoom.id), 플레이어=\(currentRoom.players.map { $0.name })")
                            print("🔍 [RoomJoinView] 전체 플레이어 정보:")
                            for (index, player) in currentRoom.players.enumerated() {
                                print("  [\(index)] name: \(player.name), id: \(player.id), isHost: \(player.isHost)")
                            }
                            
                            // 동일한 이름의 플레이어가 있는지 확인 (로그만)
                            let existingPlayer = currentRoom.players.first { $0.name == userName }
                            if let existing = existingPlayer {
                                print("ℹ️ [RoomJoinView] 동일한 이름의 플레이어 감지: \(existing.name)")
                                print("ℹ️ [RoomJoinView] 플레이어 ID: '\(existing.id)' (길이: \(existing.id.count))")
                                print("ℹ️ [RoomJoinView] 서버에서 자동으로 처리됩니다")
                            } else {
                                print("✅ [RoomJoinView] 중복 플레이어 없음 - 바로 입장 가능")
                            }
                        } else {
                            print("ℹ️ [RoomJoinView] 방이 서버 목록에 없음 - 새 방일 수 있음")
                        }
                        
                        // ✅ WebSocket 비동기 요청 (원래 이름으로 입장) - RoomViewModel 사용
                        let joined = try await roomViewModel.joinRoom(
                            roomId: room.id,
                            userName: userName,
                            password: password
                        )
                        
                        print("✅ [RoomJoinView] 방 입장 성공!")
                        print("📥 받은 방 정보: ID=\(joined.id), 제목=\(joined.title), 플레이어 수=\(joined.players.count)")
                        
                        // 성공 시 현재 방 갱신 후 이동
                        await MainActor.run {
                            roomViewModel.room = joined
                            navigateToLobby = true
                            isLoading = false
                            connectionStatus = "입장 완료!"
                            print("🎯 [RoomJoinView] 로비로 이동 설정됨")
                        }
                    } catch {
                        print("❌ [RoomJoinView] 방 입장 실패: \(error)")
                        
                        await MainActor.run {
                            alertMessage = error.localizedDescription.isEmpty
                                ? "입장에 실패했습니다."
                                : error.localizedDescription
                            showAlert = true
                            isLoading = false
                            connectionStatus = "입장 실패"
                            print("🚨 [RoomJoinView] 에러 알림 표시: \(alertMessage)")
                        }
                    }
                }
            } label: {
                HStack {
                    if isLoading { ProgressView() }
                    Text("입장하기")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("방 정보")
        // ✅ 값(Room) 전달 — Binding 아님
        .background(
            NavigationLink(
                destination: Group {
                    if navigateToLobby, let currentRoom = roomViewModel.room {
                        GameLobbyView(roomId: currentRoom.id)
                            .environmentObject(authViewModel)
                            .environmentObject(roomViewModel)
                    }
                },
                isActive: $navigateToLobby
            ) { EmptyView() }
        )
        .alert("입장 실패", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
            if alertMessage.contains("연결") {
                Button("재시도") {
                    // 재연결 시도
                    Task {
                        await MainActor.run {
                            connectionStatus = "재연결 중..."
                        }
                        WebSocketService.shared.connect()
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기
                        await MainActor.run {
                            connectionStatus = "연결 준비됨"
                        }
                    }
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // 뷰 표시 시 연결 상태 확인
            Task {
                await MainActor.run {
                    if WebSocketService.shared.isConnected {
                        connectionStatus = "연결 준비됨"
                    } else {
                        connectionStatus = "연결 확인 중..."
                        WebSocketService.shared.connect()
                    }
                }
            }
        }
    }
}
