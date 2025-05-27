import Combine
import SwiftUI
import Foundation
import WatchConnectivity

class WCSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WCSessionManager()

    // 🔥 Bomb Party 관련
    @Published var playerNumber: String = "대기 중..."
    @Published var hasBomb: Bool = false

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
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    // ✅ 메시지 수신 처리
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // 🔄 외부 뷰에서 클로저 등록 시 먼저 실행
            self.onMessageReceived?(message)

            // 🔥 이벤트 기반 처리 (공식 지원)
            if let event = message["event"] as? String {
                switch event {
                case "assignPlayer":
                    // Bomb Party: 플레이어 번호 및 폭탄 상태
                    self.playerNumber = message["playerNumber"] as? String ?? "대기 중..."
                    self.hasBomb = message["hasBomb"] as? Bool ?? false

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
                        print("🎮 currentGame updated to: \(self.currentGame)") // ✅ 로그로 확인

                
                default:
                    break
                }
            }
        }
    }
}
