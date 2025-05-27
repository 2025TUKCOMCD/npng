import Foundation
import WatchConnectivity

class PhoneWatchConnector: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchConnector()

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
                // TODO: Bomb 전달 처리 로직 추가
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

    // 필수 콜백 (비워두기)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
