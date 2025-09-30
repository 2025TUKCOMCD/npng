import Combine
import SwiftUI
import Foundation
import WatchConnectivity

class WCSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WCSessionManager()

    // 🔥 Bomb Party 관련
    @Published var playerNumber: String = "대기 중..."
    @Published var hasBomb: Bool = false
    private var myPlayerName: String? = nil  // 내 플레이어 이름 저장 (이름 기반으로 변경)
    @Published var gameEnded: Bool = false  // 게임 종료 상태
    @Published var loserName: String = ""  // 패자 이름

    // 🔥 SpyFall 관련
    @Published var role: String = "대기 중..."
    @Published var location: String = "?"
    @Published var citizenRole: String = ""

    // 🔁 메시지 수신 콜백 등록용 (SpyFallWatchView 등에서 사용)
    var onMessageReceived: (([String: Any]) -> Void)?

    @Published var currentGame: String = ""

    private override init() {
        super.init()
        activateSession()
    }

    private func activateSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // ✅ 세션 활성화 완료 콜백
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // 필요시 에러 처리
    }

    // ✅ 메시지 수신 처리
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // 🔄 외부 뷰에서 클로저 등록 시 먼저 실행
            self.onMessageReceived?(message)

            // 🔥 이벤트 기반 처리 (공식 지원)
            if let event = message["event"] as? String {
                switch event {
                case "assignPlayer":
                    // Bomb Party: 플레이어 이름 및 폭탄 상태 (이름 기반)
                    let incomingPlayerName = message["playerName"] as? String ?? message["playerNumber"] as? String ?? "대기 중..."
                    // hasBomb이 Int(1/0) 또는 Bool로 올 수 있음
                    let incomingHasBomb: Bool
                    if let boolValue = message["hasBomb"] as? Bool {
                        incomingHasBomb = boolValue
                    } else if let intValue = message["hasBomb"] as? Int {
                        incomingHasBomb = intValue == 1
                    } else {
                        incomingHasBomb = false
                    }
                    
                    // 첫 번째 assignPlayer 메시지이거나 내 플레이어인 경우만 업데이트
                    if self.myPlayerName == nil {
                        // 첫 번째 assignPlayer 메시지 - 내 플레이어로 설정
                        self.myPlayerName = incomingPlayerName
                        self.playerNumber = incomingPlayerName
                        self.hasBomb = incomingHasBomb
                    } else if self.myPlayerName == incomingPlayerName {
                        // 내 플레이어에 대한 업데이트 (이름 기반 비교)
                        self.hasBomb = incomingHasBomb
                        self.playerNumber = incomingPlayerName
                    } else {
                        // 다른 플레이어의 정보 - 무시
                    }

                case "spyAssign":
                    // SpyFall: 역할 및 장소 전달
                    self.role = message["role"] as? String ?? "Unknown"
                    self.location = message["location"] as? String ?? "?"
                    self.citizenRole = message["citizenRole"] as? String ?? ""
                    
                case "passBomb":
                    // Bomb Party: 폭탄 넘김 (옵션 처리)
                    self.hasBomb = false

                case "startGame":
                        self.currentGame = message["gameType"] as? String ?? ""
                        self.gameEnded = false  // 게임 시작 시 초기화
                        // 게임 시작 시 플레이어 정보 초기화 (새 게임을 위해)
                        self.myPlayerName = nil
                        
                case "gameEnded":
                    // 게임 종료 처리
                    self.gameEnded = true
                    self.loserName = message["loserName"] as? String ?? ""
                    
                    // 폭탄 상태 초기화
                    self.hasBomb = false
                    
                    // 3초 후 자동 리셋
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.gameEnded = false
                        self.loserName = ""
                        self.currentGame = ""
                    }

                case "gameState":
                    // 게임 상태 동기화 처리
                    let state = message["state"] as? String ?? "unknown"
                    let playerName = message["playerName"] as? String ?? "대기 중..."
                    
                    switch state {
                    case "waiting":
                        // 게임 대기 상태
                        self.playerNumber = playerName
                        self.hasBomb = false
                        self.currentGame = ""
                        
                    case "lobby":
                        // 방 대기 상태
                        self.playerNumber = playerName
                        self.hasBomb = false
                        self.currentGame = ""
                        if let roomTitle = message["roomTitle"] as? String {
                        }
                        
                    default:
                        break
                    }
                
                default:
                    break
                }
            }
        }
    }
}
