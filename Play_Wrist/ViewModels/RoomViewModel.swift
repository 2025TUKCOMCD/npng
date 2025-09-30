import Foundation
import Combine

@MainActor
final class RoomViewModel: ObservableObject {
    @Published var room: Room? = nil
    @Published var rooms: [Room] = []
    @Published var lastError: String? = nil
    @Published var isGameStarted: Bool = false  // 게임 시작 상태 추적
    
    // 현재 플레이어 정보 저장
    var currentPlayerId: String? = nil
    var currentRoomId: String? = nil

    private var bag = Set<AnyCancellable>()

    init() {
        WebSocketService.shared.connect()
        setupWatchConnector()

        // ✅ 방 목록 변경
        WebSocketService.shared.roomsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rooms in
                print("📥 [roomsSubject] 서버 응답 방목록:", rooms.map { $0.title }) // 🔎 추가
                self?.rooms = rooms
            }
            .store(in: &bag)
        
        // createRoomSubject 구독 제거 - async/await로 처리하므로 불필요

        // ✅ 방 입장 (자신 또는 다른 사람이 입장했을 때)
        WebSocketService.shared.joinedRoomSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] room in
                print("📥 [joinedRoomSubject] 방 업데이트:", room.title, "플레이어:", room.players.count)
                // 현재 방과 같은 방이면 업데이트
                if self?.room?.id == room.id {
                    self?.room = room
                    print("✅ [RoomViewModel] 현재 방 데이터 업데이트 완료")
                }
                // 방 목록도 업데이트
                if let idx = self?.rooms.firstIndex(where: { $0.id == room.id }) {
                    self?.rooms[idx] = room
                }
            }
            .store(in: &bag)

        // ✅ 방 나가기
        WebSocketService.shared.leftRoomSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                print("📥 [leftRoomSubject] 방 나감:", updated.title) // 🔎 추가
                self?.room = updated
                if let idx = self?.rooms.firstIndex(where: { $0.id == updated.id }) {
                    self?.rooms[idx] = updated
                }
            }
            .store(in: &bag)

        // ✅ 플레이어 상태 갱신
        WebSocketService.shared.playerUpdatedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                print("📥 [playerUpdatedSubject] 플레이어 갱신됨, 방:", updated.title) // 🔎 추가
                if self?.room?.id == updated.id {
                    self?.room = updated
                    // ⭐ 추가: Watch 동기화 (폭탄 넘기기 등으로 인한 상태 변경)
                    self?.syncCurrentStateToWatch()
                }
                if let idx = self?.rooms.firstIndex(where: { $0.id == updated.id }) {
                    self?.rooms[idx] = updated
                }
            }
            .store(in: &bag)

        // ✅ 게임 시작 알림
        WebSocketService.shared.gameStartedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] room in
                print("📥 [gameStartedSubject] 게임 시작됨, roomId:", room.id) // 🔎 추가
                print("   - 폭탄 소유자: \(room.currentBombHolder ?? "nil")")
                print("   - 미션: \(room.currentMission ?? "nil")")
                
                // 현재 방의 게임이 시작되었으면 상태 업데이트
                if self?.currentRoomId == room.id {
                    self?.room = room  // ⭐ 중요: room 데이터를 업데이트해야 함!
                    self?.isGameStarted = true
                    print("🎮 [RoomViewModel] 게임 시작 상태 설정: true, room 데이터 업데이트 완료")
                }
            }
            .store(in: &bag)
    }

    // MARK: - Public API (요청만 보냄, 응답은 Subject로 받음)
    func createRoom(title: String, game: String, password: String, maxPlayers: Int, hostName: String) {
        let host = Player(id: UUID().uuidString, name: hostName, isReady: true, role: nil, isHost: true)
        let draft = Room(
            id: UUID().uuidString,
            title: title,
            game: game,
            password: password,
            maxPlayers: maxPlayers,
            hostName: hostName,
            players: [host]
        )
        
        Task {
            do {
                let createdRoom = try await WebSocketService.shared.createRoom(draft)
                await MainActor.run {
                    self.room = createdRoom
                    self.currentRoomId = createdRoom.id
                    if let host = createdRoom.players.first {
                        self.currentPlayerId = host.id
                    }
                    print("✅ [RoomViewModel] 방 생성 완료 및 room 설정: \(createdRoom.title)")
                }
            } catch {
                print("❌ [RoomViewModel] 방 생성 실패: \(error)")
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func fetchRooms() {
        Task {
            await WebSocketService.shared.fetchRooms()
        }
    }

    func joinRoom(roomId: String, userName: String, password: String?) async throws -> Room {
        let room = try await WebSocketService.shared.joinRoom(roomId: roomId, userName: userName, password: password ?? "")
        
        // 입장 성공 시 현재 플레이어 정보 저장
        if let player = room.players.first(where: { $0.name == userName }) {
            self.currentPlayerId = player.id
            self.currentRoomId = room.id
            print("💾 [RoomViewModel] 플레이어 정보 저장: roomId=\(room.id), playerId=\(player.id)")
        }
        
        return room
    }

    func leaveRoom(roomId: String, playerId: String) async throws -> Room {
        let room = try await WebSocketService.shared.leaveRoomForBackButton(roomId: roomId, playerId: playerId)
        
        // 나가기 성공 시 정보 초기화
        self.currentPlayerId = nil
        self.currentRoomId = nil
        self.isGameStarted = false
        print("🧹 [RoomViewModel] 플레이어 정보 초기화")
        
        return room
    }
    
    // 현재 방에서 나가기 (뒤로가기 버튼 전용)
    func leaveCurrentRoom() {
        guard let roomId = currentRoomId, let playerId = currentPlayerId else {
            print("⚠️ [RoomViewModel] 나갈 방 정보가 없음")
            return
        }
        
        print("🚪 [RoomViewModel] 현재 방 나가기: roomId=\(roomId), playerId=\(playerId)")
        
        Task {
            do {
                _ = try await leaveRoom(roomId: roomId, playerId: playerId)
                print("✅ [RoomViewModel] 방 나가기 성공")
            } catch {
                print("❌ [RoomViewModel] 방 나가기 실패: \(error)")
            }
        }
    }

    func toggleReady(roomId: String, playerId: String) {
        print("🔔 [RoomViewModel] toggleReady 호출됨 - roomId: \(roomId), playerId: \(playerId)")
        WebSocketService.shared.toggleReady(roomId: roomId, playerId: playerId)
    }

    func setRole(roomId: String, playerId: String, role: String?) {
        WebSocketService.shared.setRole(roomId: roomId, playerId: playerId, role: role)
    }

    func startGame(roomId: String, idToken: String) {
        // 게임 시작 요청 시 즉시 상태 설정
        isGameStarted = true
        print("🎮 [RoomViewModel] startGame 호출 - 게임 시작 상태 설정: true")
        
        WebSocketService.shared.startGame(roomId: roomId)
    }

    func disconnectWebSocket() {
        WebSocketService.shared.disconnect()
    }
    
    // MARK: - Watch 동기화 설정
    
    private func setupWatchConnector() {
        // Watch 연결 시 현재 상태 동기화
        PhoneWatchConnector.shared.onWatchConnected = { [weak self] in
            self?.syncCurrentStateToWatch()
        }
        
        // Watch에서 폭탄 전달 요청 시 처리
        PhoneWatchConnector.shared.onBombPass = { [weak self] playerName in
            guard let self = self else { return }
            
            print("💣 [RoomViewModel] Watch에서 폭탄 전달 요청 - from: \(playerName)")
            
            // 현재 플레이어 ID 찾기
            guard let currentRoom = self.room,
                  let player = currentRoom.players.first(where: { $0.name == playerName }) else {
                print("❌ [RoomViewModel] 플레이어를 찾을 수 없음: \(playerName)")
                return
            }
            
            // 서버에 폭탄 전달 요청
            Task {
                do {
                    let updatedRoom = try await WebSocketService.shared.passBomb(
                        roomId: currentRoom.id,
                        playerId: player.id
                    )
                    
                    await MainActor.run {
                        self.room = updatedRoom
                        print("✅ [RoomViewModel] 폭탄 전달 완료 - 새 소유자: \(updatedRoom.currentBombHolder ?? "nil")")
                        
                        // ⭐ 수정: 모든 플레이어의 Watch에 업데이트된 상태 전송
                        PhoneWatchConnector.shared.syncToAllPlayers(room: updatedRoom)
                    }
                } catch {
                    print("❌ [RoomViewModel] 폭탄 전달 실패: \(error)")
                }
            }
        }
    }
    
    /// Watch에 현재 상태 동기화
    private func syncCurrentStateToWatch() {
        print("🔄 [RoomViewModel] Watch 연결됨 - 현재 상태 동기화 시작")
        
        // 현재 플레이어 이름 추출
        let currentPlayerName: String?
        if let playerId = currentPlayerId, let room = room {
            currentPlayerName = room.players.first { $0.id == playerId }?.name
        } else {
            currentPlayerName = nil
        }
        
        print("🔄 [RoomViewModel] 현재 방: \(room?.title ?? "없음"), 플레이어: \(currentPlayerName ?? "없음")")
        PhoneWatchConnector.shared.syncCurrentGameState(room: room, currentPlayerName: currentPlayerName)
    }
    
    /// 게임 플레이 상태를 Watch에 동기화
    private func syncGamePlayState(room: Room, currentPlayerName: String?) {
        PhoneWatchConnector.shared.syncCurrentGameState(room: room, currentPlayerName: currentPlayerName)
    }
}
