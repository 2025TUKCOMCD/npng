import Foundation
import Combine

// MARK: - STOMP WebSocket Service (URLSessionWebSocketTask + STOMP text frames)
//
// Note:
// - 이 파일에서는 WSRequest / WSResponse 등의 타입을 재사용합니다.
//   해당 타입들은 프로젝트의 다른 파일(예: WebSocketModels.swift)에 이미 정의되어 있어야 합니다.
// - 서버의 STOMP 목적지(destination) 네이밍과 reply/queue 정책에 맞춰
//   actionToDestination(...)와 setupDefaultSubscriptions()의 목적지를 수정하세요.

@MainActor
final class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    private init() {}

    // 서버 WebSocket URL (ws or wss)
    private let wsURLString = "ws://43.201.195.113:8000/ws"
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)

    // STOMP state
    private var connected = false
    private var sessionId: String? // 서버에서 CONNECTED 헤더로 주는 session id (선택)
    private var receiveLoopActive = false

    // heartbeat timer (optional simple implementation)
    private var heartbeatTimer: Timer?

    // 요청-응답 매칭: reqId -> resolver
    private var pending: [String: (Result<Data, Error>) -> Void] = [:]

    // subscription id -> destination
    private var subscriptions: [String: String] = [:]

    // Subjects for server push (기존 API와 동일한 Subject들)
    let roomsSubject = PassthroughSubject<[Room], Never>()
    let joinedRoomSubject = PassthroughSubject<Room, Never>()
    let leftRoomSubject = PassthroughSubject<Room, Never>()
    let playerUpdatedSubject = PassthroughSubject<Room, Never>()
    let gameStartedSubject = PassthroughSubject<String, Never>() // roomId

    // MARK: - Connect / Disconnect (STOMP)

    func connect() {
        guard webSocketTask == nil, let url = URL(string: wsURLString) else { return }
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        startReceiveLoop()
        sendConnectFrame()
        startHeartbeat()
    }

    func disconnect() {
        stopHeartbeat()
        receiveLoopActive = false
        sendDisconnectFrame()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connected = false
        sessionId = nil
        subscriptions.removeAll()
        pending.removeAll()
    }

    // MARK: Heartbeat

    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }

    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    private func sendHeartbeat() {
        guard let task = webSocketTask, connected else { return }
        task.send(.string("\n")) { error in
            if let e = error { print("heartbeat send error: \(e)") }
        }
    }

    // MARK: STOMP frame helpers

    private func sendFrame(command: String, headers: [String: String] = [:], body: String? = nil) {
        guard let task = webSocketTask else { return }
        var frame = command + "\n"
        for (k, v) in headers {
            frame += "\(k):\(v)\n"
        }
        frame += "\n"
        if let b = body { frame += b }
        frame += "\u{0}" // STOMP null terminator

        task.send(.string(frame)) { error in
            if let e = error { print("sendFrame error for \(command): \(e)") }
        }
    }

    private func startReceiveLoop() {
        guard let task = webSocketTask, !receiveLoopActive else { return }
        receiveLoopActive = true

        func recv() {
            task.receive { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let err):
                    print("receive error: \(err)")
                    self.receiveLoopActive = false
                    self.disconnect()
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleIncomingStomp(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleIncomingStomp(text)
                        } else {
                            print("Received binary but cannot decode to text")
                        }
                    @unknown default:
                        break
                    }
                    if self.receiveLoopActive { recv() }
                }
            }
        }
        recv()
    }

    // MARK: STOMP CONNECT / SUBSCRIBE / SEND / DISCONNECT frames

    private func sendConnectFrame() {
        // TODO: 서버 요구사항에 맞춰 CONNECT 헤더(Authorization, login/passcode 등)를 추가하세요.
        sendFrame(command: "CONNECT", headers: [
            "accept-version": "1.1,1.2",
            "host": "localhost", // adjust if needed
            "heart-beat": "10000,10000"
        ], body: nil)
    }

    private func sendDisconnectFrame() {
        sendFrame(command: "DISCONNECT")
    }

    private func subscribe(id: String, destination: String) {
        sendFrame(command: "SUBSCRIBE", headers: [
            "id": id,
            "destination": destination,
            "ack": "auto"
        ])
        subscriptions[id] = destination
    }

    private func unsubscribe(id: String) {
        sendFrame(command: "UNSUBSCRIBE", headers: ["id": id])
        subscriptions.removeValue(forKey: id)
    }

    // MARK: STOMP incoming parser & router

    private func handleIncomingStomp(_ raw: String) {
        // raw may contain multiple frames; split by null char (STOMP terminator)
        let frames = raw.split(separator: "\u{0}", omittingEmptySubsequences: true).map { String($0) }
        for frame in frames { handleFrame(frame) }
    }

    private func handleFrame(_ frame: String) {
        let lines = frame.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        guard let command = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        // parse headers
        var headers: [String: String] = [:]
        var i = 1
        while i < lines.count {
            let line = lines[i]
            if line == "" { i += 1; break }
            if let idx = line.firstIndex(of: ":") {
                let key = String(line[..<idx])
                let value = String(line[line.index(after: idx)...])
                headers[key] = value
            }
            i += 1
        }

        // body (may contain newlines)
        let body = lines.dropFirst(i).joined(separator: "\n")

        switch command {
        case "CONNECTED":
            self.connected = true
            self.sessionId = headers["session"]
            print("STOMP CONNECTED session=\(sessionId ?? "nil")")
            setupDefaultSubscriptions()
        case "MESSAGE":
            routeMessage(headers: headers, body: body)
        case "RECEIPT":
            // optional: receipt handling
            print("STOMP RECEIPT: \(headers)")
        case "ERROR":
            print("STOMP ERROR: headers=\(headers) body=\(body)")
        default:
            print("Unhandled STOMP command: \(command)")
        }
    }

    private func routeMessage(headers: [String: String], body: String) {
        let dest = headers["destination"] ?? headers["subscription"] ?? ""
        guard let data = body.data(using: .utf8) else { return }

        // correlation-id or reply queue resolution
        if let correlation = headers["correlation-id"], let resolver = pending.removeValue(forKey: correlation) {
            resolver(.success(data)); return
        }

        if let lastComp = dest.split(separator: "/").last, lastComp.starts(with: "reply-") {
            let reqId = String(lastComp.dropFirst("reply-".count))
            if let resolver = pending.removeValue(forKey: reqId) {
                resolver(.success(data)); return
            }
        }

        // ROUTING: 목적지에 따라 Subjects로 라우팅 (서버 목적지에 맞게 수정)
        switch dest {
        case "/topic/rooms":
            if let res = try? JSONDecoder().decode(WSResponse<RoomsUpdatedPayload>.self, from: data),
               let rooms = res.payload?.rooms {
                roomsSubject.send(rooms)
            } else if let list = try? JSONDecoder().decode([Room].self, from: data) {
                roomsSubject.send(list)
            }
        case "/topic/joined":
            if let res = try? JSONDecoder().decode(WSResponse<JoinedPayload>.self, from: data),
               let room = res.payload?.room {
                joinedRoomSubject.send(room)
            }
        case "/topic/left":
            if let res = try? JSONDecoder().decode(WSResponse<LeftPayload>.self, from: data),
               let room = res.payload?.room {
                leftRoomSubject.send(room)
            }
        case "/topic/playerUpdated":
            if let res = try? JSONDecoder().decode(WSResponse<PlayerUpdatedPayload>.self, from: data),
               let room = res.payload?.room {
                playerUpdatedSubject.send(room)
            }
        case "/topic/gameStarted":
            struct GameStartedPayload: Codable { let roomId: String }
            if let res = try? JSONDecoder().decode(WSResponse<GameStartedPayload>.self, from: data),
               let roomId = res.payload?.roomId {
                gameStartedSubject.send(roomId)
            }
        default:
            if let generic = try? JSONDecoder().decode(WSResponse<FetchRoomsPayload>.self, from: data) {
                print("Generic MESSAGE for dest=\(dest) decoded: \(generic)")
            } else {
                print("Unhandled MESSAGE for dest=\(dest): \(String(data: data, encoding: .utf8) ?? "<binary>")")
            }
        }
    }

    // MARK: Default subscriptions (adjust per backend)

    private func setupDefaultSubscriptions() {
        // TODO: 서버가 사용하는 실제 토픽 이름을 확인 후 수정하세요.
        subscribe(id: "sub-rooms", destination: "/topic/rooms")
        subscribe(id: "sub-joined", destination: "/topic/joined")
        subscribe(id: "sub-left", destination: "/topic/left")
        subscribe(id: "sub-playerUpdated", destination: "/topic/playerUpdated")
        subscribe(id: "sub-gameStarted", destination: "/topic/gameStarted")

        // 개인 대상 메시지가 있다면 추가로 구독
        // e.g. subscribe(id: "sub-private", destination: "/user/queue/updates")
    }

    // MARK: - action -> destination mapping

    private func actionToDestination(_ action: WSAction) -> String {
        // 기본 매핑: /app/<action>
        // 서버의 규칙에 맞춰 변경하세요.
        let actionName = String(describing: action)
        return "/app/\(actionName)"
    }

    // MARK: - Request/Response over STOMP

    private func sendRequest<RQ: Codable, RS: Codable>(
        _ action: WSAction,
        payload: RQ?,
        responseType: RS.Type
    ) async throws -> RS {
        guard webSocketTask != nil, connected else { throw URLError(.notConnectedToInternet) }

        let reqId = UUID().uuidString
        let destination = actionToDestination(action)

        // reply queue & subscription (server must route reply to this path)
        let replyDestination = "/user/queue/reply-\(reqId)"
        let subId = "sub-reply-\(reqId)"
        subscribe(id: subId, destination: replyDestination)

        // prepare request JSON wrapper (using existing WSRequest type)
        let requestBody: String
        if let p = payload {
            let wrapper = WSRequest<RQ>(action: action, requestId: reqId, payload: p)
            let d = try JSONEncoder().encode(wrapper)
            guard let s = String(data: d, encoding: .utf8) else { throw NSError(domain: "WS", code: -100, userInfo: [NSLocalizedDescriptionKey: "UTF8 encode failed"]) }
            requestBody = s
        } else {
            let wrapper = WSRequest<RQ>(action: action, requestId: reqId, payload: nil)
            let d = try JSONEncoder().encode(wrapper)
            guard let s = String(data: d, encoding: .utf8) else { throw NSError(domain: "WS", code: -100, userInfo: [NSLocalizedDescriptionKey: "UTF8 encode failed"]) }
            requestBody = s
        }

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<RS, Error>) in
            pending[reqId] = { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let err):
                    cont.resume(throwing: err)
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
                    } catch {
                        cont.resume(throwing: error)
                    }
                }
                // cleanup
                self.unsubscribe(id: subId)
                self.pending.removeValue(forKey: reqId)
            }

            let headers: [String: String] = [
                "destination": destination,
                "reply-to": replyDestination,
                "correlation-id": reqId,
                "content-type": "application/json"
            ]
            self.sendFrame(command: "SEND", headers: headers, body: requestBody)
        }
    }

    // MARK: - Public API (Room 관련) — 기존 API 유지

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

// ------------------------------------------------------------
// NOTE: WSRequest, WSResponse, WSAction, Room 및 각 Payload/Result 타입들은
// 프로젝트 내 다른 파일에서 정의되어 있어야 합니다.
// 예: WebSocketModels.swift 등에 이미 선언되어 있는지 확인하세요.
// ------------------------------------------------------------
