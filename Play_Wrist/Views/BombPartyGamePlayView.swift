import SwiftUI

struct BombPartyGamePlayView: View {
    let roomId: String
    @EnvironmentObject var authViewModel: AppleSignInViewModel
    @EnvironmentObject var roomViewModel: RoomViewModel
    
    // 게임 시작 상태를 추적하는 State 변수 추가
    @State private var gameStarted: Bool = false
    @State private var refreshTrigger: Bool = false
    
    // 실시간 room 데이터 가져오기
    private var room: Room? {
        // refreshTrigger를 사용하여 강제 업데이트
        let _ = refreshTrigger
        
        // 먼저 roomViewModel.room 확인
        if let currentRoom = roomViewModel.room, currentRoom.id == roomId {
            return currentRoom
        }
        // 없으면 rooms 배열에서 찾기
        return roomViewModel.rooms.first { $0.id == roomId }
    }
    
    // 현재 플레이어 이름 계산
    private var currentPlayerName: String? {
        guard let room = room,
              let playerId = roomViewModel.currentPlayerId else { return nil }
        return room.players.first { $0.id == playerId }?.name
    }

    var body: some View {
        ZStack {
            if let room = room {
                gameContentView(room: room)
            } else {
                emptyStateView
            }
        }
        .onReceive(roomViewModel.$room) { updatedRoom in
            handleRoomUpdate(updatedRoom)
        }
        .onAppear {
            handleOnAppear()
        }
    }
    
    // 빈 상태 뷰
    private var emptyStateView: some View {
        Text("방 정보를 불러올 수 없습니다")
            .foregroundColor(.red)
    }
    
    // 게임 컨텐츠 뷰를 별도 함수로 분리
    @ViewBuilder
    private func gameContentView(room: Room) -> some View {
        VStack(spacing: 20) {
            headerSection(room: room)
            debugInfoSection(room: room)
            actionButtonsSection()
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    // 헤더 섹션
    @ViewBuilder
    private func headerSection(room: Room) -> some View {
        VStack(spacing: 15) {
            Text("💣 Bomb Party Game")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .padding()

            Text("방 제목: \(room.title)")
                .font(.title2)
                .padding()

            // 플레이어 목록을 별도 변수로 분리
            let playerNames = room.players.map { $0.name }.joined(separator: ", ")
            Text("게임 참가자: \(playerNames)")
                .font(.body)
                .padding()
        }
    }
    
    // 디버그 정보 섹션
    @ViewBuilder
    private func debugInfoSection(room: Room) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🔍 디버그 정보")
                .font(.headline)
                .foregroundColor(.blue)
            
            playerInfoSection(room: room)
            bombInfoSection(room: room)
            playerListSection(room: room)
            missionSection(room: room)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // 현재 플레이어 정보 (제거됨)
    @ViewBuilder
    private func playerInfoSection(room: Room) -> some View {
        EmptyView()
    }
    
    // 폭탄 정보
    @ViewBuilder
    private func bombInfoSection(room: Room) -> some View {
        Group {
            // 폭탄 소유자 이름
            HStack {
                Text("💣 폭탄 소유자 이름:")
                    .fontWeight(.semibold)
                if let bombHolderId = room.currentBombHolder,
                   let bombHolder = room.players.first(where: { $0.id == bombHolderId }) {
                    Text(bombHolder.name)
                        .foregroundColor(.red)
                } else {
                    Text("없음")
                        .foregroundColor(.gray)
                }
            }
            
            // 내가 폭탄을 가지고 있는지
            bombOwnershipSection(room: room)
        }
    }
    
    // 폭탄 소유 여부 체크
    @ViewBuilder
    private func bombOwnershipSection(room: Room) -> some View {
        HStack {
            Text("🎯 내가 폭탄 소유:")
                .fontWeight(.semibold)
            
            let bombHolderName = getBombHolderName(room: room)
            let hasBomb = checkHasBomb(bombHolderName: bombHolderName)
            
            Text(hasBomb ? "YES" : "NO")
                .foregroundColor(hasBomb ? .red : .green)
                .fontWeight(.bold)
        }
    }
    
    // 폭탄 소유자 이름 가져오기
    private func getBombHolderName(room: Room) -> String? {
        guard let bombHolderId = room.currentBombHolder else { return nil }
        return room.players.first(where: { $0.id == bombHolderId })?.name
    }
    
    // 폭탄 소유 여부 체크
    private func checkHasBomb(bombHolderName: String?) -> Bool {
        let hasBomb = currentPlayerName == bombHolderName
        print("🔍 [BombPartyGamePlayView] 폭탄 소유 체크: currentPlayerName=\(currentPlayerName ?? "nil"), bombHolderName=\(bombHolderName ?? "nil"), hasBomb=\(hasBomb)")
        return hasBomb
    }
    
    // 플레이어 목록
    @ViewBuilder
    private func playerListSection(room: Room) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("👥 플레이어 목록:")
                .fontWeight(.semibold)
            ForEach(room.players, id: \.id) { player in
                playerRow(player: player, room: room)
            }
        }
    }
    
    // 플레이어 행
    @ViewBuilder
    private func playerRow(player: Player, room: Room) -> some View {
        HStack {
            Text("• \(player.name)")
            if player.name == currentPlayerName {
                Text("(나)")
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            }
            if player.id == room.currentBombHolder {
                Text("💣")
            }
        }
    }
    
    // 미션 섹션 (제거됨)
    @ViewBuilder
    private func missionSection(room: Room) -> some View {
        EmptyView()
    }
    
    // 액션 버튼들 (주석처리됨)
    @ViewBuilder
    private func actionButtonsSection() -> some View {
        /* 폭탄 넘기기 버튼 - 테스트 완료 후 주석처리
        if let room = room {
            // 현재 플레이어가 폭탄을 가지고 있는지 확인
            let bombHolderName = getBombHolderName(room: room)
            let hasBomb = checkHasBomb(bombHolderName: bombHolderName)
            
            if hasBomb {
                VStack(spacing: 15) {
                    Text("💣 폭탄을 가지고 있습니다!")
                        .font(.headline)
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                    
                    Button(action: {
                        passBombToNextPlayer()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("폭탄 넘기기")
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(15)
                    }
                    
                    Text("테스트용: 폭탄을 다음 플레이어에게 넘깁니다")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
        */
        EmptyView()
    }
    
    // Room 업데이트 처리
    private func handleRoomUpdate(_ updatedRoom: Room?) {
        guard let updatedRoom = updatedRoom,
              updatedRoom.id == roomId else { return }
        
        print("🔄 [BombPartyGamePlayView] Room 업데이트 감지")
        print("   - 게임 시작 상태: \(updatedRoom.started)")
        print("   - 폭탄 소유자: \(updatedRoom.currentBombHolder ?? "nil")")
        
        // 게임이 시작되었고, 폭탄 소유자가 설정된 경우
        if updatedRoom.started == true && updatedRoom.currentBombHolder != nil && !gameStarted {
            print("🎮 [BombPartyGamePlayView] 게임 시작 감지! View 강제 업데이트")
            gameStarted = true
            refreshTrigger.toggle()  // View 강제 업데이트
            
            // 🔥 게임 시작시 자동으로 Watch에 메시지 전송
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sendGameStartToWatch()
                self.sendSyncToWatch()
            }
        }
        
        // 폭탄 소유자가 변경된 경우에도 업데이트
        if updatedRoom.currentBombHolder != nil {
            refreshTrigger.toggle()
        }
    }
    
    // View 나타날 때 처리
    private func handleOnAppear() {
        print("🔍 [BombPartyGamePlayView] View 나타남")
        print("   - roomId: \(roomId)")
        print("   - currentPlayerName: \(currentPlayerName ?? "nil")")
        print("   - room 상태: \(room?.started == true ? "게임 중" : "대기 중")")
        print("   - 폭탄 소유자: \(room?.currentBombHolder ?? "nil")")
        
        // View가 나타날 때 한 번 더 체크
        if let room = room,
           room.started == true,
           room.currentBombHolder != nil {
            gameStarted = true
            refreshTrigger.toggle()
            
            // 🔥 이미 게임이 시작된 상태에서 View가 나타난 경우 Watch 동기화
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.sendGameStartToWatch()
                self.sendSyncToWatch()
            }
        }
    }
    
    // ✅ Watch로 '게임 시작' 메시지 보내기
    private func sendGameStartToWatch() {
        let message: [String: Any] = [
            "event": "gameStart",
            "game": "Bomb Party"
        ]
        PhoneWatchConnector.shared.send(message: message)
    }
    
    // 🔄 Watch 동기화 디버그 버튼
    private func sendSyncToWatch() {
        guard let room = room else { return }
        
        // 현재 플레이어 이름 가져오기
        let currentPlayerName = self.currentPlayerName
        
        print("📱 [디버그] Watch 동기화 시작")
        print("   - 내 ID: \(roomViewModel.currentPlayerId ?? "없음")")
        print("   - 내 이름: \(currentPlayerName ?? "없음")")
        print("   - 폭탄 소유자 ID: \(room.currentBombHolder ?? "없음")")
        
        // PhoneWatchConnector를 통해 동기화
        PhoneWatchConnector.shared.syncCurrentGameState(room: room, currentPlayerName: currentPlayerName)
    }
    
    // 💣 폭탄 넘기기 (테스트용)
    private func passBombToNextPlayer() {
        guard let room = room,
              let currentPlayerName = currentPlayerName,
              let currentPlayerId = roomViewModel.currentPlayerId else {
            print("❌ [폭탄 넘기기] 필요한 정보가 없습니다.")
            return
        }
        
        print("💣 [iOS] 폭탄 넘기기 버튼 클릭 - 플레이어: \(currentPlayerName)")
        
        Task {
            do {
                let updatedRoom = try await WebSocketService.shared.passBomb(
                    roomId: room.id,
                    playerId: currentPlayerId
                )
                
                await MainActor.run {
                    // Room 업데이트는 playerUpdatedSubject를 통해 자동으로 처리됨
                    print("✅ [iOS] 폭탄 전달 완료 - 새 소유자: \(updatedRoom.currentBombHolder ?? "nil")")
                }
            } catch {
                await MainActor.run {
                    print("❌ [iOS] 폭탄 전달 실패: \(error)")
                }
            }
        }
    }
}