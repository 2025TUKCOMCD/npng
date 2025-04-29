import Combine
import SwiftUI
import Foundation
import WatchConnectivity

class WCSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WCSessionManager()

    @Published var playerNumber: String = "대기 중..."  // 🔥 내 플레이어 번호 (ex: Player1)
    @Published var hasBomb: Bool = false                // 🔥 폭탄 보유 여부

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

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let event = message["event"] as? String {
                if event == "assignPlayer" {
                    // 🔥 Bomb Party용 메시지 처리
                    self.playerNumber = message["playerNumber"] as? String ?? "대기 중..."
                    self.hasBomb = message["hasBomb"] as? Bool ?? false
                }
                else if event == "passBomb" {
                    // 나중에 폭탄 넘기기 처리 필요 시 여기 추가
                }
            }
        }
    }
}
