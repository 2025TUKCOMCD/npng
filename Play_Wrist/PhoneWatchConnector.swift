import Foundation
import WatchConnectivity

class PhoneWatchConnector: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchConnector()
    
    // 현재 게임 상태 콜백
    var onWatchConnected: (() -> Void)?
    
    // 폭탄 전달 콜백 (RoomViewModel에서 설정)
    var onBombPass: ((String) -> Void)?

    private override init() {
        super.init()
        activateSession()
    }

    // ✅ 세션 활성화
    private func activateSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // ✅ 일반 메시지 전송 (Broadcast용)
    func send(message: [String: Any]) {
        print("📤 iPhone → Watch 전송: \(message)")
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("❌ 메시지 전송 실패: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ Watch 연결 안 됨")
        }
    }

    // ✅ 특정 유저용 전송 → 현재는 1:1 환경이므로 send와 동일하게 처리
    func sendToSpecificWatch(for player: String, message: [String: Any]) {
        print("📤 특정 유저 [\(player)] 에게 전송: \(message)")
        send(message: message)
    }

    // ✅ 예시: Bomb Party Ready 상태 전송
    func sendUserInfoToWatch(userName: String, status: String) {
        let message: [String: Any] = [
            "event": "playerReady",
            "userName": userName,
            "status": status
        ]
        send(message: message)
    }

    // 🔄 Watch → iPhone 메시지 수신 처리
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("📩 iPhone 수신 메시지 (from Watch): \(message)")

        guard let event = message["event"] as? String else { return }

        switch event {
        case "passBomb":
            if let player = message["playerNumber"] as? String {
                print("💣 폭탄 넘김 감지! from \(player)")
                // RoomViewModel에서 설정한 콜백 호출
                onBombPass?(player)
            }

        case "spyVote":
            if let spyGuess = message["suspect"] as? String {
                print("🕵️ 스파이로 의심된 사람: \(spyGuess)")
                // TODO: Spy Fall 투표 처리 추가
            }

        default:
            print("⚠️ 미처리 이벤트: \(event)")
        }
    }

    // MARK: - WCSessionDelegate 메서드들
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 [PhoneWatchConnector] WCSession이 비활성화됨")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 [PhoneWatchConnector] WCSession이 해제됨")
    }
    #endif
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("📱 [PhoneWatchConnector] WCSession 활성화 완료: \(activationState.rawValue)")
        
        if activationState == .activated {
            DispatchQueue.main.async {
                self.checkWatchConnection()
            }
        }
    }
    
    // Watch 연결 상태 체크 및 동기화
    private func checkWatchConnection() {
        if WCSession.default.isReachable {
            print("⌚ [PhoneWatchConnector] Watch 연결됨 - 현재 상태 동기화 시작")
            onWatchConnected?()
        } else {
            print("⌚ [PhoneWatchConnector] Watch 연결되지 않음")
        }
    }
    
    // MARK: - 게임 상태 동기화
    
    /// 현재 게임 상태를 Watch에 동기화 (이름 기반)
    func syncCurrentGameState(room: Room?, currentPlayerName: String?) {
        guard WCSession.default.isReachable else {
            print("⚠️ [PhoneWatchConnector] Watch 연결되지 않음 - 동기화 건너뜀")
            return
        }
        
        guard let room = room else {
            print("📤 [PhoneWatchConnector] 게임 상태 없음 - 대기 상태 전송")
            send(message: [
                "event": "gameState",
                "state": "waiting",
                "playerName": currentPlayerName ?? "대기 중..."
            ])
            return
        }
        
        // 게임이 시작되지 않은 경우
        guard room.started == true else {
            print("📤 [PhoneWatchConnector] 게임 시작 전 - 대기 상태 전송")
            send(message: [
                "event": "gameState", 
                "state": "lobby",
                "playerName": currentPlayerName ?? "대기 중...",
                "roomTitle": room.title
            ])
            return
        }
        
        // 게임 진행 중인 경우 - 전체 상태 동기화
        syncGamePlayState(room: room, currentPlayerName: currentPlayerName)
    }
    
    /// 게임 플레이 상태 동기화 (게임 시작 후) - 이름 기반
    private func syncGamePlayState(room: Room, currentPlayerName: String?) {
        print("🎮 [PhoneWatchConnector] 게임 플레이 상태 동기화 시작")
        
        // 먼저 게임 타입 전송
        send(message: [
            "event": "startGame",
            "gameType": room.game == "Bomb Party" ? "BombParty" : "SpyFall"
        ])
        
        // 현재 플레이어만 찾아서 상태 전송
        guard let currentPlayerName = currentPlayerName,
              let currentPlayer = room.players.first(where: { $0.name == currentPlayerName }) else {
            print("⚠️ [PhoneWatchConnector] 현재 플레이어를 찾을 수 없음: \(currentPlayerName ?? "nil")")
            return
        }
        
        guard let bombHolderId = room.currentBombHolder else {
            print("⚠️ [PhoneWatchConnector] currentBombHolder가 nil")
            return
        }
        
        // 폭탄 소유자의 이름 찾기
        let bombHolderName = room.players.first(where: { $0.id == bombHolderId })?.name
        let hasBomb = currentPlayer.name == bombHolderName
        
        // 현재 플레이어의 정보만 전송 (이름 기반)
        let message: [String: Any] = [
            "event": "assignPlayer",
            "playerName": currentPlayer.name,  // 이름 사용
            "hasBomb": hasBomb,
            "mission": room.currentMission ?? "FAST_TAP"
        ]
        
        print("📤 [PhoneWatchConnector] 현재 플레이어 상태 동기화 - \(currentPlayer.name): hasBomb=\(hasBomb)")
        send(message: message)
    }
    
    /// 모든 플레이어에게 게임 상태 동기화 (폭탄 넘기기 등으로 인한 상태 변경 시 사용)
    func syncToAllPlayers(room: Room) {
        print("🔄 [PhoneWatchConnector] 모든 플레이어에게 상태 동기화 시작")
        
        guard WCSession.default.isReachable else {
            print("⚠️ [PhoneWatchConnector] Watch 연결되지 않음 - 전체 동기화 건너뜀")
            return
        }
        
        guard room.started == true else {
            print("📤 [PhoneWatchConnector] 게임 시작 전 - 전체 동기화 건너뜀")
            return
        }
        
        // 모든 플레이어에 대해 개별 동기화
        for player in room.players {
            syncGamePlayState(room: room, currentPlayerName: player.name)
        }
    }
}
