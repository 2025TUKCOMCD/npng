import Foundation
import WatchConnectivity

class PhoneWatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func startGameOnWatch() {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["command": "startGame"], replyHandler: nil) { error in
                print("❌ Error sending message: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ Watch is not reachable")
        }
    }

    // ✅ 필수 메서드들 구현
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("✅ WCSession activated: \(activationState.rawValue)")
    }

    // iOS에서는 이 2개도 필수
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("ℹ️ sessionDidBecomeInactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("ℹ️ sessionDidDeactivate")
        // session 재활성화 필요할 수도 있음
        WCSession.default.activate()
    }
}
