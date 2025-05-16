import Foundation
import Combine

/// SwiftUI WebSocket 매니저
final class WebSocketManager: ObservableObject {
    private var task: URLSessionWebSocketTask?
    private let url: URL

    @Published var isConnected = false
    @Published var lastEvent: Event?

    /// 서버에서 수신되는 이벤트 정의
    enum Event: Decodable {
        case join(userId: Int?)
        case leave(userId: Int?)
        case message(userId: Int?, payload: Payload)

        private enum CodingKeys: String, CodingKey { case event, user_id, payload }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let event = try container.decode(String.self, forKey: .event)
            let uid = try? container.decode(Int.self, forKey: .user_id)

            switch event {
            case "join":
                self = .join(userId: uid)
            case "leave":
                self = .leave(userId: uid)
            case "message":
                let payload = try container.decode(Payload.self, forKey: .payload)
                self = .message(userId: uid, payload: payload)
            default:
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unknown event type"))
            }
        }
    }

    /// 초기화 시 URL 구성
    init(roomID: Int, host: String, port: Int, token: String?) {
        var comp = URLComponents()
        comp.scheme = host.starts(with: "https") ? "wss" : "ws"
        comp.host = comp.scheme == "wss" ? host.replacingOccurrences(of: "https://", with: "") : host.replacingOccurrences(of: "http://", with: "")
        comp.port = port
        comp.path = "/ws/rooms/\(roomID)"
        if let t = token {
            comp.queryItems = [URLQueryItem(name: "token", value: t)]
        }
        guard let u = comp.url else {
            fatalError("❌ WebSocket URL 생성 실패")
        }
        url = u
    }

    /// 서버에 연결 시작
    func connect() {
        task = URLSession.shared.webSocketTask(with: url)
        task?.resume()
        isConnected = true
        receive()
    }

    /// 서버로부터 메시지 수신
    private func receive() {
        task?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("❌ WebSocket 수신 에러: \(error)")
                self?.isConnected = false

            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self?.decodeAndHandle(data: data)
                    }
                case .data(let data):
                    self?.decodeAndHandle(data: data)
                @unknown default:
                    break
                }

                // 다음 메시지도 계속 받기
                self?.receive()
            }
        }
    }

    /// 메시지 디코딩 처리
    private func decodeAndHandle(data: Data) {
        do {
            let event = try JSONDecoder().decode(Event.self, from: data)
            DispatchQueue.main.async {
                self.lastEvent = event
            }
        } catch {
            print("❌ 디코딩 실패: \(error)")
        }
    }

    /// 서버로 메시지 전송
    func send<T: Encodable>(_ payload: T) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        task?.send(.data(data)) { error in
            if let e = error {
                print("❌ WebSocket 전송 실패: \(e)")
            }
        }
    }

    /// 연결 해제
    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
}

/// WebSocket 메시지 payload 구조체
struct Payload: Codable {
    let message: String?
    let action: String?
}
