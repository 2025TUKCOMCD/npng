import Combine
import SwiftUI
import Foundation
import WatchConnectivity


class WCSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WCSessionManager()

    @Published var playerName: String = ""
    @Published var status: String = ""
    @Published var isGameStarted: Bool = false
    @Published var isPlayerReady: Bool = false

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
            if message["event"] as? String == "gameStart" {
                self.playerName = message["assignedPlayer"] as? String ?? "player?"
                self.status = message["status"] as? String ?? "대기 중"
                self.isGameStarted = true
            } else if message["event"] as? String == "playerReady" {
                self.playerName = message["userName"] as? String ?? "플레이어"
                self.status = message["status"] as? String ?? "Ready"
                self.isPlayerReady = true
            }
        }
    }
}
