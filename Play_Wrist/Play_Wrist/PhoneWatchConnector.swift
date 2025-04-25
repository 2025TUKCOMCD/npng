import Foundation
import WatchConnectivity

class PhoneWatchConnector: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchConnector()

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

    func sendUserInfoToWatch(userName: String, status: String) {
        if WCSession.default.isReachable {
            let message: [String: Any] = [
                "userName": userName,
                "status": status
            ]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("❌ 메시지 전송 실패: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ Apple Watch 연결 안 됨")
        }
    }
    func send(message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("❌ 메시지 전송 실패: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ Watch 연결 안 됨")
        }
    }

    // 필요 없지만 구현은 해줘야 함
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
