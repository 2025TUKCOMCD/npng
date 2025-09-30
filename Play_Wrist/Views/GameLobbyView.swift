import SwiftUI
import FirebaseAuth
import Combine

struct GameLobbyView: View {
    let roomId: String  // 방 ID만 저장

    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @EnvironmentObject var roomViewModel: RoomViewModel    // ✅ 상위에서 주입되어야 함
    @Environment(\.dismiss) private var dismiss

    @State private var shouldNavigateToBombParty = false
    @State private var shouldNavigateToSpyFall = false
    @State private var isLeavingForGame = false  // 게임 시작으로 인한 이동 추적
    @State private var currentRoom: Room? = nil  // 현재 방 상태를 저장
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isInitialLoad = true  // 초기 로드 상태 추적
    @State private var showGameEndAlert = false  // 게임 종료 알림
    @State private var gameEndMessage = ""  // 게임 종료 메시지
    @State private var loserName = ""  // 패자 이름
    @State private var hasLeftRoom = false  // 이미 방을 나갔는지 추적
    
    init(roomId: String) {
        self.roomId = roomId
    }


    var body: some View {
        // currentRoom이 nil이면 즉시 roomViewModel.room 확인
        let displayRoom = currentRoom ?? roomViewModel.room
        
        if let room = displayRoom {
            let fullPlayers = getFullPlayers(from: room)
            let leftPlayers = Array(fullPlayers.prefix(fullPlayers.count / 2))
            let rightPlayers = Array(fullPlayers.suffix(fullPlayers.count - fullPlayers.count / 2))
            VStack(spacing: 16) {
                // 상단 바
                HStack {
                    Button(action: { 
                        // 방 나가기 처리
                        leaveRoomAndDismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("게임 선택")
                        }
                        .foregroundColor(.blue)
                    }
                    Spacer()
                    Text("Play Wrist")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.purple)

                // 게임명 카드
                Text(room.game)
                .foregroundColor(.purple)
                .font(.headline)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple, lineWidth: 1)
                )

            // 사용자 카드 리스트
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 16) {
                    ForEach(leftPlayers.indices, id: \.self) { index in
                        let player = leftPlayers[index]
                        playerCard(name: player, isReady: isPlayerReady(player, in: room))
                    }
                }
                VStack(spacing: 16) {
                    ForEach(rightPlayers.indices, id: \.self) { index in
                        let player = rightPlayers[index]
                        playerCard(name: player, isReady: isPlayerReady(player, in: room))
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // 🔹 버튼 영역
            if authViewModel.userName == room.hostName {
                Button(action: startGameTapped) {
                    Text("Start")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            } else {
                // 준비 완료 버튼 (호스트가 아닌 경우)
                let userName = authViewModel.userName ?? "이름 없음"
                let currentPlayer = room.players.first { $0.name == userName }
                let isReady = currentPlayer?.isReady ?? false
                
                VStack {
                    Button(action: {
                        print("🔴🔴🔴 버튼 액션 시작! 🔴🔴🔴")
                        print("🎯 [GameLobbyView] 준비 버튼 클릭됨! userName: \(userName)")
                        print("🎯 [GameLobbyView] authViewModel.userName: \(authViewModel.userName ?? "nil")")
                        print("🎯 [GameLobbyView] 방의 플레이어들: \(room.players.map { $0.name })")
                        
                        // 실제 Room 데이터에서 플레이어 찾기
                        if let player = room.players.first(where: { $0.name == userName }) {
                            print("🎯 [GameLobbyView] 플레이어 찾음: \(player.name), id: \(player.id), isReady: \(player.isReady)")
                            roomViewModel.toggleReady(roomId: room.id, playerId: player.id)
                        } else {
                            print("❌ [GameLobbyView] 현재 플레이어를 찾을 수 없음: \(userName)")
                            print("❌ [GameLobbyView] 방의 모든 플레이어:")
                            for p in room.players {
                                print("  - name: '\(p.name)', id: \(p.id)")
                            }
                        }
                    }) {
                        Text(isReady ? "준비 취소" : "준비 완료")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isReady ? Color.gray : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(false)  // 명시적으로 활성화
                    .allowsHitTesting(true)  // 터치 이벤트 허용
                    .onTapGesture {
                        print("🟡🟡🟡 onTapGesture 감지됨! 🟡🟡🟡")
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }

            // Navigation Links
            NavigationLink(
                destination: BombPartyGamePlayView(roomId: room.id)
                    .environmentObject(authViewModel)
                    .environmentObject(roomViewModel),
                isActive: $shouldNavigateToBombParty
            ) { EmptyView() }

            NavigationLink(
                destination: SpyFallGamePlayView(room: room).environmentObject(authViewModel),
                isActive: $shouldNavigateToSpyFall
            ) { EmptyView() }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .alert("게임 종료", isPresented: $showGameEndAlert) {
                Button("확인") {
                    // 게임 초기화
                    shouldNavigateToBombParty = false
                    shouldNavigateToSpyFall = false
                    isLeavingForGame = false
                }
            } message: {
                Text(gameEndMessage)
            }
            .onAppear {
            print("🎮 [GameLobbyView] onAppear - roomId: \(roomId)")
            print("🎮 [GameLobbyView] roomViewModel.room: \(roomViewModel.room?.id ?? "nil")")
            print("🎮 [GameLobbyView] roomViewModel.rooms count: \(roomViewModel.rooms.count)")
            
            // 초기화 시 즉시 방 찾기
            if currentRoom == nil {
                // roomViewModel.room이 일치하면 사용
                if let room = roomViewModel.room, room.id == roomId {
                    currentRoom = room
                    print("🎮 [GameLobbyView] roomViewModel.room 사용: \(room.id)")
                }
                // rooms에서 찾기
                else if let room = roomViewModel.rooms.first(where: { $0.id == roomId }) {
                    currentRoom = room
                    print("🎮 [GameLobbyView] rooms에서 찾음: \(room.id)")
                }
                // 그래도 없으면 roomViewModel.room 사용 (방 생성/입장 직후)
                else if let room = roomViewModel.room {
                    currentRoom = room
                    print("🎮 [GameLobbyView] fallback to roomViewModel.room: \(room.id)")
                }
            }
            
            print("🎮 [GameLobbyView] After initialization - currentRoom: \(currentRoom?.id ?? "nil")")
            
            // RoomViewModel의 room 변화 감지
            roomViewModel.$room
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    updateCurrentRoom()
                }
                .store(in: &cancellables)
            
            // RoomViewModel의 rooms 변화 감지
            roomViewModel.$rooms
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    updateCurrentRoom()
                }
                .store(in: &cancellables)
            
            // 게임 시작 브로드캐스트 구독 (참가자용)
            WebSocketService.shared.gameStartedSubject
                .sink { gameRoom in
                    // 현재 방의 게임 시작 신호를 받았을 때
                    if gameRoom.id == roomId {
                        print("🎮 [GameLobbyView] 게임 시작 브로드캐스트 수신: roomId=\(gameRoom.id)")
                        print("🎮 [GameLobbyView] 폭탄 소유자: \(gameRoom.currentBombHolder ?? "nil"), 미션: \(gameRoom.currentMission ?? "nil")")
                        
                        // 즉시 게임으로 이동 중임을 표시 (leaveRoom 방지)
                        isLeavingForGame = true
                        
                        // 게임 타입에 따라 화면 전환
                        DispatchQueue.main.async {
                            if gameRoom.game == "Bomb Party" {
                                // Watch로 게임 시작 상태 전송
                                sendGameStateToWatch(room: gameRoom)
                                sendReadyPlayersToWatch()
                                shouldNavigateToBombParty = true
                                PhoneWatchConnector.shared.send(message: ["event": "startGame", "gameType": "BombParty"])
                            } else if gameRoom.game == "SPY Fall" {
                                shouldNavigateToSpyFall = true
                                PhoneWatchConnector.shared.send(message: ["event": "startGame", "gameType": "SpyFall"])
                            }
                        }
                    }
                }
                .store(in: &cancellables)
            
            // 폭탄 폭발 이벤트 구독
            WebSocketService.shared.bombExplodedSubject
                .receive(on: DispatchQueue.main)
                .sink { (roomId, loserId) in
                    print("💥 [GameLobbyView] 폭탄 폭발 이벤트 수신! roomId: \(roomId), loserId: \(loserId)")
                    
                    // 현재 방과 일치하는지 확인
                    if roomId == self.roomId {
                        // 패자 이름 찾기
                        if let room = currentRoom,
                           let loser = room.players.first(where: { $0.id == loserId }) {
                            loserName = loser.name
                            gameEndMessage = "\(loser.name)님이 폭탄을 폭발시켰습니다!💥"
                        } else {
                            gameEndMessage = "폭탄이 폭발했습니다!💥"
                        }
                        
                        // watchOS에 게임 종료 알림
                        PhoneWatchConnector.shared.send(message: [
                            "event": "gameEnded",
                            "loserId": loserId,
                            "loserName": loserName,
                            "reason": "bombExploded"
                        ])
                        
                        // 알림 표시
                        showGameEndAlert = true
                        
                        // 방 상태 업데이트 (게임 종료)
                        if var room = currentRoom {
                            room.started = false
                            room.currentBombHolder = nil
                            room.currentMission = nil
                            currentRoom = room
                            roomViewModel.room = room
                        }
                    }
                }
                .store(in: &cancellables)
        }
            .onDisappear {
                // 구독 해제만 수행 (방 나가기는 뒤로가기 버튼에서만)
                cancellables.removeAll()
            }
        } else {
            // room이 nil인 경우 로딩 뷰 표시
            ProgressView("방 정보를 불러오는 중...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.ignoresSafeArea())
                .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Actions
    
    private func updateCurrentRoom() {
        // roomId가 비어있거나 "temp"인 경우 roomViewModel.room 사용
        if roomId.isEmpty || roomId == "temp" {
            currentRoom = roomViewModel.room
        } 
        // 현재 roomId와 일치하는 방 찾기
        else if let room = roomViewModel.room, room.id == roomId {
            currentRoom = room
        } else if let room = roomViewModel.rooms.first(where: { $0.id == roomId }) {
            currentRoom = room
        }
        // 그래도 못 찾으면 roomViewModel.room 사용 (방 생성 직후)
        else if roomViewModel.room != nil {
            currentRoom = roomViewModel.room
        }
    }
    
    private func leaveRoomAndDismiss() {
        // 뒤로가기 버튼에서만 실제 방 나가기 수행
        print("🚪 [GameLobbyView] 뒤로가기 - 방 나가기 실행")
        roomViewModel.leaveCurrentRoom()
        dismiss()
    }

    private func startGameTapped() {
        guard let room = currentRoom else { return }
        
        // 최소 인원 체크
        if room.players.count < 2 {
            print("❌ [GameLobbyView] 최소 2명 이상 필요합니다. 현재: \(room.players.count)명")
            // TODO: Alert 표시
            return
        }
        
        // 모든 플레이어 준비 상태 확인
        let notReadyPlayers = room.players.filter { !$0.isReady }
        if !notReadyPlayers.isEmpty {
            print("⚠️ [GameLobbyView] 준비 안된 플레이어: \(notReadyPlayers.map { $0.name })")
            print("⚠️ [GameLobbyView] 준비 안된 플레이어 상세:")
            for player in notReadyPlayers {
                print("  - \(player.name): id=\(player.id), isReady=\(player.isReady)")
            }
            // 준비되지 않은 플레이어가 있으면 시작 불가
            print("❌ [GameLobbyView] 모든 플레이어가 준비되어야 합니다.")
            return
        }
        
        print("🎮 [GameLobbyView] 게임 시작 요청: roomId=\(room.id)")
        print("📋 [GameLobbyView] 현재 플레이어 상태:")
        for player in room.players {
            print("  - \(player.name): id=\(player.id), isReady=\(player.isReady)")
        }
        
        // 게임으로 이동 중임을 미리 표시 (leaveRoom 방지)
        isLeavingForGame = true
        
        // WebSocket으로 startGame 요청
        roomViewModel.startGame(roomId: room.id, idToken: "")
        
        // 게임 시작 브로드캐스트를 기다리지 않고 즉시 화면 전환
        // (서버 응답은 gameStartedSubject로 처리)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if room.game == "Bomb Party" {
                sendReadyPlayersToWatch()
                shouldNavigateToBombParty = true
                PhoneWatchConnector.shared.send(message: ["event": "startGame", "gameType": "BombParty"])
            } else if room.game == "SPY Fall" {
                shouldNavigateToSpyFall = true
                PhoneWatchConnector.shared.send(message: ["event": "startGame", "gameType": "SpyFall"])
            }
        }
    }

    // MARK: - Helpers

    private func isPlayerReady(_ name: String, in room: Room) -> Bool {
        // 실제 Room 데이터에서 플레이어의 isReady 상태 확인
        return room.players.first { $0.name == name }?.isReady ?? false
    }

    private func getFullPlayers(from room: Room) -> [String] {
        
        // 순서를 유지하기 위해 Array 사용
        var playerNames: [String] = []
        
        // 호스트를 먼저 추가
        playerNames.append(room.hostName)
        
        // 나머지 플레이어들을 추가 (호스트가 아닌 경우만)
        for player in room.players {
            if player.name != room.hostName && !playerNames.contains(player.name) {
                playerNames.append(player.name)
            }
        }
        
        // 빈 슬롯 추가
        let emptySlots = max(0, room.maxPlayers - playerNames.count)
        return playerNames + Array(repeating: "", count: emptySlots)
    }

    private func sendReadyPlayersToWatch() {
        guard let room = currentRoom else { return }
        // Room 데이터에서 직접 준비된 플레이어 확인
        for player in room.players where player.isReady {
            let message: [String: Any] = ["event": "playerReady", "userName": player.name, "status": "Ready"]
            PhoneWatchConnector.shared.send(message: message)
        }
    }
    
    // 게임 시작 시 각 플레이어별 폭탄 상태를 Watch로 전송
    private func sendGameStateToWatch(room: Room) {
        print("📤 [GameLobbyView] sendGameStateToWatch 호출됨")
        
        // 현재 폭탄 소유자 찾기
        guard let bombHolderId = room.currentBombHolder else {
            print("⚠️ [GameLobbyView] currentBombHolder가 nil입니다")
            return
        }
        
        // PhoneWatchConnector의 syncGamePlayState를 사용하여 현재 플레이어만 동기화
        // 중복 메시지 전송 제거 - PhoneWatchConnector가 처리함
    }

    func playerCard(name: String, isReady: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.purple)

            Text(name.isEmpty ? "대기 중..." : name)
                .font(.body)
                .foregroundColor(.black)

            Text(isReady ? "Ready" : "Normal")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isReady ? .orange : .gray)
        }
        .frame(width: 80, height: 90)
        .padding()
        .background(Color.purple.opacity(0.15))
        .cornerRadius(16)
    }
}
