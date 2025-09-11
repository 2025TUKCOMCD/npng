import Foundation
import Combine

// MARK: - WebSocket Service

@MainActor
final class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    private init() {}

    private let wsURLString = "ws://43.201.195.113:8000/ws"
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)

    private var receiveLoopActive = false
    private var pingTimer: Timer?

    // 요청/응답 매칭
    private var pending: [String: (Result<Data, Error>) -> Void] = [:]

    // 서버 푸시
    let roomsSubject = PassthroughSubject<[Room], Never>()
    let joinedRoomSubject = PassthroughSubject<Room, Never>()
    let leftRoomSubject = PassthroughSubject<Room, Never>()
    let playerUpdatedSubject = PassthroughSubject<Room, Never>()
    let gameStartedSubject = PassthroughSubject<String, Never>() // roomId

    // MARK: connect / disconnect

    func connect() {
        guard webSocketTask == nil, let url = URL(string: wsURLString) else { return }
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        startReceiveLoop()
        startPing()
    }

    func disconnect() {
        pingTimer?.invalidate(); pingTimer = nil
        receiveLoopActive = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    private func startPing() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { await self?.sendPing() }
        }
    }

    private func sendPing() async {
        guard let task = webSocketTask else { return }
        let ping = WSRequest<FetchRoomsPayload>(action: .ping, requestId: UUID().uuidString, payload: nil)
        if let data = try? JSONEncoder().encode(ping),
           let text = String(data: data, encoding: .utf8) {
            task.send(.string(text)) { error in
                if let error = error { print("Ping error: \(error)") }
            }
        }
    }

    private func startReceiveLoop() {
        guard let task = webSocketTask, !receiveLoopActive else { return }
        receiveLoopActive = true
        func recv() {
            task.receive { [weak self] result in
                guard let self else { return }
                switch result {
                case .failure(let err):
                    print("receive error: \(err)")
                    self.receiveLoopActive = false
                    self.disconnect() // 재연결 없음
                case .success(let msg):
                    self.handle(message: msg)
                    if self.receiveLoopActive { recv() }
                }
            }
        }
        recv()
    }

    private func handle(message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8) else { return }
            routeIncoming(data: data)
        case .data(let data):
            routeIncoming(data: data)
        @unknown default: break
        }
    }

    private func routeIncoming(data: Data) {
        struct Head: Codable { let action: WSAction; let requestId: String?; let error: String? }
        guard let head = try? JSONDecoder().decode(Head.self, from: data) else {
            print("unknown msg: \(String(data: data, encoding: .utf8) ?? "")"); return
        }

        // 요청-응답 매칭
        if let reqId = head.requestId, let resolver = pending.removeValue(forKey: reqId) {
            resolver(.success(data)); return
        }

        // 서버 푸시
        switch head.action {
        case .roomsUpdated:
            if let res = try? JSONDecoder().decode(WSResponse<RoomsUpdatedPayload>.self, from: data),
               let rooms = res.payload?.rooms { roomsSubject.send(rooms) }
        case .joined:
            if let res = try? JSONDecoder().decode(WSResponse<JoinedPayload>.self, from: data),
               let room = res.payload?.room { joinedRoomSubject.send(room) }
        case .left:
            if let res = try? JSONDecoder().decode(WSResponse<LeftPayload>.self, from: data),
               let room = res.payload?.room { leftRoomSubject.send(room) }
        case .playerUpdated:
            if let res = try? JSONDecoder().decode(WSResponse<PlayerUpdatedPayload>.self, from: data),
               let room = res.payload?.room { playerUpdatedSubject.send(room) }
        case .gameStarted:
            struct GameStartedPayload: Codable { let roomId: String }
            if let res = try? JSONDecoder().decode(WSResponse<GameStartedPayload>.self, from: data),
               let roomId = res.payload?.roomId { gameStartedSubject.send(roomId) }
        case .pong: break
        case .error:
            if let res = try? JSONDecoder().decode(WSResponse<FetchRoomsPayload>.self, from: data) {
                print("server error push: \(res.error ?? "unknown")")
            }
        default:
            print("unhandled push: \(head.action)")
        }
    }

    // MARK: Request/Response 공통

    private func sendRequest<RQ: Codable, RS: Codable>(
        _ action: WSAction,
        payload: RQ?,
        responseType: RS.Type
    ) async throws -> RS {
        guard let task = webSocketTask else { throw URLError(.notConnectedToInternet) }

        let reqId = UUID().uuidString
        let request = WSRequest<RQ>(action: action, requestId: reqId, payload: payload)
        let data = try JSONEncoder().encode(request)
        guard let text = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "WS", code: -100, userInfo: [NSLocalizedDescriptionKey: "UTF-8 encode failed"])
        }

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<RS, Error>) in
            pending[reqId] = { [weak self] result in
                guard let self else { return }
                switch result {
                case .failure(let err): cont.resume(throwing: err)
                case .success(let data):
                    do {
                        let decoded = try JSONDecoder().decode(WSResponse<RS>.self, from: data)
                        if let err = decoded.error {
                            cont.resume(throwing: NSError(domain: "WS", code: -1, userInfo: [NSLocalizedDescriptionKey: err]))
                        } else if let payload = decoded.payload {
                            cont.resume(returning: payload)
                        } else {
                            cont.resume(throwing: NSError(domain: "WS", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty payload"]))
                        }
                    } catch { cont.resume(throwing: error) }
                }
                self.pending.removeValue(forKey: reqId)
            }

            task.send(.string(text)) { [weak self] error in
                if let error { _ = self?.pending.removeValue(forKey: reqId); cont.resume(throwing: error) }
            }
        }
    }

    // MARK: Public API (Room 관련)

    func fetchRooms() async throws -> [Room] {
        struct RoomsList: Codable { let rooms: [Room] }
        let res: RoomsList = try await sendRequest(.fetchRooms, payload: FetchRoomsPayload(), responseType: RoomsList.self)
        return res.rooms
    }

    func createRoom(_ room: Room) async throws -> Room {
        let res: CreateRoomResult = try await sendRequest(.createRoom, payload: CreateRoomPayload(room: room), responseType: CreateRoomResult.self)
        return res.room
    }

    func joinRoom(roomId: String, userName: String, password: String) async throws -> Room {
        let res: JoinRoomResult = try await sendRequest(.joinRoom, payload: JoinRoomPayload(roomId: roomId, userName: userName, password: password), responseType: JoinRoomResult.self)
        return res.room
    }

    func leaveRoom(roomId: String, playerId: String) async throws -> Room {
        let res: LeaveRoomResult = try await sendRequest(.leaveRoom, payload: LeaveRoomPayload(roomId: roomId, playerId: playerId), responseType: LeaveRoomResult.self)
        return res.room
    }

    func toggleReady(roomId: String, playerId: String) async throws -> Room {
        let res: ToggleReadyResult = try await sendRequest(.toggleReady, payload: ToggleReadyPayload(roomId: roomId, playerId: playerId), responseType: ToggleReadyResult.self)
        return res.room
    }

    func setRole(roomId: String, playerId: String, role: String?) async throws -> Room {
        let res: SetRoleResult = try await sendRequest(.setRole, payload: SetRolePayload(roomId: roomId, playerId: playerId, role: role), responseType: SetRoleResult.self)
        return res.room
    }

    func startGame(roomId: String, idToken: String) async throws -> Bool {
        let res: StartGameResult = try await sendRequest(.startGame, payload: StartGamePayload(roomId: roomId, idToken: idToken), responseType: StartGameResult.self)
        return res.success
    }
}


