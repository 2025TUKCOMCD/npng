import Foundation
import Combine

@MainActor
final class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    private init() {}

    // WebSocket 서버 주소
//    private let wsURLString = "wss://student-login-serivc.p-e.kr/ws-game/websocket" //원래 서버용
    private let wsURLString = "ws://34.64.51.95:8083/ws"  // GCP 테스트용
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    let connectionId = UUID().uuidString

    private var connected = false
    private var sessionId: String?
    private var receiveLoopActive = false
    private var heartbeatTimer: Timer?
    
    // 연결 상태 확인용 computed property
    var isConnected: Bool {
        return connected && webSocketTask != nil
    }

    private var pending: [String: (Result<Data, Error>) -> Void] = [:]
    private var subscriptions: [String: String] = [:]

    // Subjects
    let roomsSubject = PassthroughSubject<[Room], Never>()
    let createRoomSubject = PassthroughSubject<Room, Never>()  // 방 생성 응답용 Subject 추가
    let joinedRoomSubject = PassthroughSubject<Room, Never>()
    let leftRoomSubject = PassthroughSubject<Room, Never>()
    let playerUpdatedSubject = PassthroughSubject<Room, Never>()
    let gameStartedSubject = PassthroughSubject<Room, Never>()
    let bombExplodedSubject = PassthroughSubject<(roomId: String, loserId: String), Never>()  // 폭탄 폭발 이벤트
    let bombPassedSubject = PassthroughSubject<Room, Never>()  // 폭탄 전달 이벤트

    // MARK: - Connect / Disconnect
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

    // MARK: STOMP Frame Helpers
    private func sendFrame(command: String, headers: [String: String] = [:], body: String? = nil) {
        guard let task = webSocketTask else { return }
        var frame = command + "\n"
        for (k, v) in headers {
            frame += "\(k):\(v)\n"
        }
        frame += "\n"
        if let b = body { frame += b }
        frame += "\u{0}"

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

    // MARK: STOMP CONNECT / DISCONNECT
    private func sendConnectFrame() {
        sendFrame(command: "CONNECT", headers: [
            "accept-version": "1.1,1.2",
            "host": "34.64.51.95:8083"
        ])
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

    // MARK: Incoming Parser & Router
    private func handleIncomingStomp(_ raw: String) {
        let frames = raw.split(separator: "\u{0}", omittingEmptySubsequences: true).map { String($0) }
        for frame in frames { handleFrame(frame) }
    }

    private func handleFrame(_ frame: String) {
        let lines = frame.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        guard let command = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        
        // 모든 프레임 로깅 (디버깅용)
        if command != "" && !command.isEmpty {
            print("📨 [STOMP Frame] Command: \(command)")
        }

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

        let body = lines.dropFirst(i).joined(separator: "\n")

        switch command {
        case "CONNECTED":
            connected = true
            sessionId = headers["session"]
            print("✅ STOMP CONNECTED session=\(sessionId ?? "nil")")
            print("🔗 WebSocket 연결 성공!")
            setupDefaultSubscriptions()

        case "MESSAGE":
            routeMessage(headers: headers, body: body)

        case "RECEIPT":
            print("STOMP RECEIPT: \(headers)")

        case "ERROR":
            print("❌ STOMP ERROR: headers=\(headers) body=\(body)")
            // ERROR 메시지를 pending 요청에 전달
            if let correlationId = headers["correlation-id"], 
               let completion = pending[correlationId] {
                completion(.failure(WebSocketError.serverError(body)))
                pending.removeValue(forKey: correlationId)
            }

        default:
            print("⚠️ Unhandled STOMP command: \(command)")
        }
    }

    private func routeMessage(headers: [String: String], body: String) {
        let dest = headers["destination"] ?? ""
        print("📥 MESSAGE dest=\(dest)")
        print("📥 raw body:", body)
        
        // joinRoom 응답 특별 디버깅
        if dest.contains("joinRoom") || body.contains("\"action\":\"joinRoom\"") {
            print("🔍🔍🔍 [JOINROOM DEBUG] destination: \(dest)")
            print("🔍🔍🔍 [JOINROOM DEBUG] headers: \(headers)")
            print("🔍🔍🔍 [JOINROOM DEBUG] body: \(body)")
        }
        
        guard let data = body.data(using: .utf8) else { return }

        // Broadcast 라우팅
        switch dest {
        case "/topic/fetchRooms" :
            do {
                let res = try JSONDecoder().decode(WSResponse<[Room]>.self, from: data)
                if let rooms = res.payload {
                    print("✅ fetchRooms rooms:", rooms)
                    roomsSubject.send(rooms)
                }
            } catch {
                print("❌ fetchRooms decode error:", error, "raw:", body)
            }
        case "/topic/createRoom":
            // 브로드캐스트는 방 목록 업데이트용
            do {
                let res = try JSONDecoder().decode(WSResponse<[Room]>.self, from: data)
                if let rooms = res.payload {
                    print("✅ createRoom broadcast - rooms list updated:", rooms.count, "rooms")
                    roomsSubject.send(rooms)
                    // createRoomSubject는 개별 응답에서만 처리
                }
            } catch {
                print("❌ createRoom broadcast decode error:", error)
            }
        case "/topic/roomsUpdated":
            do {
                let res = try JSONDecoder().decode(WSResponse<[Room]>.self, from: data)
                if let rooms = res.payload {
                    print("✅ roomsUpdated rooms:", rooms)
                    roomsSubject.send(rooms)
                }
            } catch {

            }
        case "/topic/joined":
            print("🎯 [routeMessage] /topic/joined 브로드캐스트 수신!")
            // 서버는 Room 객체를 직접 보냄
            do {
                let res = try JSONDecoder().decode(WSResponse<Room>.self, from: data)
                if let room = res.payload {
                    print("✅ [routeMessage] joined broadcast - room: \(room.title), players: \(room.players.count)")
                    joinedRoomSubject.send(room)
                }
            } catch {
                print("❌ [routeMessage] joined decode error: \(error)")
            }
        case "/topic/left":
            do {
                let res = try JSONDecoder().decode(WSResponse<Room>.self, from: data)
                if let room = res.payload {
                    leftRoomSubject.send(room)
                }
            } catch {
                print("❌ [routeMessage] left decode error: \(error)")
            }
        case "/topic/playerUpdated":
            do {
                let res = try JSONDecoder().decode(WSResponse<Room>.self, from: data)
                if let room = res.payload {
                    playerUpdatedSubject.send(room)
                }
            } catch {
                print("❌ [routeMessage] playerUpdated decode error: \(error)")
            }
        case "/topic/gameStarted":
            print("🎮 [routeMessage] /topic/gameStarted 브로드캐스트 수신!")
            do {
                // 서버는 Room 객체를 브로드캐스트함
                let res = try JSONDecoder().decode(WSResponse<Room>.self, from: data)
                if let room = res.payload {
                    print("✅ [routeMessage] gameStarted - roomId: \(room.id), game: \(room.game)")
                    print("✅ [routeMessage] currentBombHolder: \(room.currentBombHolder ?? "nil"), mission: \(room.currentMission ?? "nil")")
                    gameStartedSubject.send(room)  // Room 객체 전체 전달
                }
            } catch {
                print("❌ [routeMessage] gameStarted decode error: \(error)")
                print("❌ [routeMessage] raw body: \(body)")
            }
        case "/topic/game":
            print("💥 [routeMessage] /topic/game 이벤트 수신!")
            do {
                // 서버에서 전송하는 게임 이벤트 처리
                if let jsonData = body.data(using: .utf8),
                   let gameEvent = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    
                    print("💥 [routeMessage] game event: \(gameEvent)")
                    
                    if let action = gameEvent["action"] as? String,
                       let payload = gameEvent["payload"] as? [String: Any] {
                        
                        switch action {
                        case "bombExploded":
                            if let roomId = payload["roomId"] as? String,
                               let loserId = payload["loserId"] as? String {
                                print("💥💥💥 [routeMessage] 폭탄 폭발! roomId: \(roomId), loserId: \(loserId)")
                                print("💥 [routeMessage] 게임 종료 - 패자: \(loserId)")
                                bombExplodedSubject.send((roomId: roomId, loserId: loserId))
                            }
                        default:
                            print("⚠️ [routeMessage] 알 수 없는 게임 액션: \(action)")
                        }
                    }
                }
            } catch {
                print("❌ [routeMessage] /topic/game decode error: \(error)")
                print("❌ [routeMessage] raw body: \(body)")
            }
        case let dest where dest.starts(with: "/user/queue/reply-") || dest.starts(with: "/queue/reply-"):
            // 개별 응답 처리 - /user/queue/reply- 또는 /queue/reply- 형태 모두 처리
            let reqId: String
            if dest.starts(with: "/user/queue/reply-") {
                reqId = String(dest.dropFirst("/user/queue/reply-".count))
            } else {
                reqId = String(dest.dropFirst("/queue/reply-".count))
            }
            print("🔍 [routeMessage] 개별 응답 수신 - dest: \(dest)")
            print("🔍 [routeMessage] 추출된 reqId: \(reqId)")
            print("🔍 [routeMessage] pending keys: \(Array(pending.keys))")
            
            if let completion = pending[reqId] {
                print("✅ [routeMessage] pending 찾음, 완료 처리")
                
                // 디버깅: 원본 응답 확인
                print("📦 [routeMessage] 원본 응답 데이터: \(String(data: data, encoding: .utf8) ?? "decode failed")")
                
                completion(.success(data))
                pending.removeValue(forKey: reqId)
                unsubscribe(id: "reply-\(reqId)")
            } else {
                print("❌ [routeMessage] pending에서 reqId 못찾음: \(reqId)")
            }
        default:
            print("Unhandled MESSAGE dest=\(dest): \(body)")
        }
    }

    // MARK: Default Subscriptions
    private func setupDefaultSubscriptions() {
        subscribe(id: "sub-user-clientId", destination: "/user/queue/reply-\(connectionId)")
        subscribe(id: "sub-fetchRooms", destination: "/topic/fetchRooms")
        subscribe(id: "sub-createRoom", destination: "/topic/createRoom")  // 방 생성 브로드캐스트 구독 추가
        subscribe(id: "sub-roomsUpdated", destination: "/topic/roomsUpdated")
        subscribe(id: "sub-joined", destination: "/topic/joined")
        subscribe(id: "sub-left", destination: "/topic/left")
        subscribe(id: "sub-playerUpdated", destination: "/topic/playerUpdated")
        subscribe(id: "sub-gameStarted", destination: "/topic/gameStarted")
        subscribe(id: "sub-game", destination: "/topic/game")
    }

    // MARK: action -> destination
    private func actionToDestination(_ action: WSAction) -> String {
        return "/app/\(String(describing: action))"
    }

    // MARK: sendRequest
    private func sendRequest<RQ: Codable>(
        _ action: WSAction,
        payload: RQ?
    ) {
        guard webSocketTask != nil, connected else { return }

        let reqId = connectionId
        let destination = actionToDestination(action)
        let replyDestination = "/user/queue/reply-\(reqId)"

        let wrapper = WSRequest<RQ>(action: action, requestId: reqId, payload: payload)
        guard let requestBody = try? String(data: JSONEncoder().encode(wrapper), encoding: .utf8) else {
            print("❌ UTF8 encode failed")
            return
        }

        let headers: [String: String] = [
            "destination": destination,
            "reply-to": replyDestination,
            "correlation-id": reqId,
            "content-type": "application/json"
        ]
        sendFrame(command: "SEND", headers: headers, body: requestBody)
    }

    // MARK: sendRequestAsync
    private func sendRequestAsync<RQ: Codable, RS: Codable>(
        _ action: WSAction,
        payload: RQ?,
        responseType: RS.Type
    ) async throws -> RS {
        guard webSocketTask != nil, connected else {
            throw WebSocketError.notConnected
        }

        let reqId = UUID().uuidString
        let destination = actionToDestination(action)
        // STOMP /user prefix는 서버에서 자동 처리하므로 클라이언트는 /queue로 구독
        let replyDestination = "/queue/reply-\(reqId)"
        
        print("🔧 [sendRequestAsync] reqId: \(reqId)")
        print("🔧 [sendRequestAsync] destination: \(destination)")
        print("🔧 [sendRequestAsync] replyDestination: \(replyDestination)")

        return try await withCheckedThrowingContinuation { continuation in
            // 응답 대기 등록을 구독보다 먼저!
            pending[reqId] = { result in
                switch result {
                case .success(let data):
                    do {
                        // 디버깅: 원본 데이터 출력
                        let rawString = String(data: data, encoding: .utf8) ?? "decode failed"
                        print("🔍 [sendRequestAsync] 원본 응답: \(rawString)")
                        
                        let response = try JSONDecoder().decode(WSResponse<RS>.self, from: data)
                        print("🔍 [sendRequestAsync] 디코드된 응답 - action: \(response.action), error: \(response.error ?? "nil"), payload 존재: \(response.payload != nil)")
                        
                        if let error = response.error {
                            continuation.resume(throwing: WebSocketError.serverError(error))
                        } else if let payload = response.payload {
                            continuation.resume(returning: payload)
                        } else {
                            print("⚠️ [sendRequestAsync] payload가 nil이어서 emptyResponse 발생")
                            continuation.resume(throwing: WebSocketError.emptyResponse)
                        }
                    } catch {
                        print("❌ [sendRequestAsync] 디코딩 실패: \(error)")
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            print("✅ [sendRequestAsync] pending 등록 완료 - reqId: \(reqId)")
            
            // 개별 응답 구독 설정
            print("🔔 [sendRequestAsync] 구독 설정 - id: reply-\(reqId), dest: \(replyDestination)")
            subscribe(id: "reply-\(reqId)", destination: replyDestination)

            // 요청 전송
            let wrapper = WSRequest<RQ>(action: action, requestId: reqId, payload: payload)
            guard let requestBody = try? String(data: JSONEncoder().encode(wrapper), encoding: .utf8) else {
                pending.removeValue(forKey: reqId)
                unsubscribe(id: "reply-\(reqId)")
                continuation.resume(throwing: WebSocketError.encodingFailed)
                return
            }

            let headers: [String: String] = [
                "destination": destination,
                "reply-to": replyDestination,
                "correlation-id": reqId,
                "content-type": "application/json"
            ]
            sendFrame(command: "SEND", headers: headers, body: requestBody)
            
            // 타임아웃 처리 (5초로 단축)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if self.pending[reqId] != nil {
                    self.pending.removeValue(forKey: reqId)
                    self.unsubscribe(id: "reply-\(reqId)")
                    continuation.resume(throwing: WebSocketError.timeout)
                }
            }
        }
    }

    // MARK: - Helper Functions
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw WebSocketError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Public API

    func fetchRooms() async {
        print("📤 [WebSocketService] fetchRooms 호출됨")
        print("📤 [WebSocketService] 연결 상태: \(isConnected)")
        
        // fire-and-forget 방식으로 변경 - 응답 대기하지 않음
        // 서버는 브로드캐스트만 보내므로 개별 응답을 기다리지 않음
        sendRequest(.fetchRooms, payload: Optional<Room>.none)
        
        print("📤 [WebSocketService] fetchRooms 요청 전송 완료 (브로드캐스트 대기)")
    }
    
    func createRoom(_ room: Room) async throws -> Room {
        print("🏠 [WebSocketService] createRoom 호출됨 - title: \(room.title)")
        
        // 연결 상태 확인
        if !isConnected {
            print("⚠️ [WebSocketService] WebSocket이 연결되지 않음. 재연결 시도...")
            connect()
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
            
            if !isConnected {
                throw WebSocketError.notConnected
            }
        }
        
        // 브로드캐스트를 통해 응답 받기 (개별 응답 대신)
        return try await withCheckedThrowingContinuation { continuation in
            let roomId = room.id  // 클라이언트에서 생성한 고유 ID
            var hasResponded = false
            
            // 브로드캐스트 구독으로 생성된 방 찾기
            let cancellable = roomsSubject
                .compactMap { rooms in
                    rooms.first { $0.id == roomId }
                }
                .first()
                .sink { createdRoom in
                    if !hasResponded {
                        hasResponded = true
                        print("✅ [WebSocketService] createRoom 브로드캐스트에서 방 찾음: \(createdRoom.title)")
                        self.createRoomSubject.send(createdRoom)
                        continuation.resume(returning: createdRoom)
                    }
                }
            
            // 타임아웃 설정
            Task {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5초 타임아웃
                if !hasResponded {
                    hasResponded = true
                    cancellable.cancel()
                    continuation.resume(throwing: WebSocketError.timeout)
                }
            }
            
            // 요청 전송
            sendRequest(.createRoom, payload: CreateRoomPayload(room: room))
        }
    }

    func joinRoom(roomId: String, userName: String, password: String) async throws -> Room {
        print("🔗 [WebSocketService] joinRoom 호출됨 - roomId: \(roomId), userName: \(userName)")
        print("🔗 [WebSocketService] 현재 pending 요청 수: \(pending.count)")
        print("🔗 [WebSocketService] 현재 구독 수: \(subscriptions.count)")
        
        // 브로드캐스트 리스너 설정 (폴백용)
        var broadcastRoom: Room? = nil
        let broadcastListener = joinedRoomSubject.sink { room in
            if room.id == roomId {
                print("🎯 [WebSocketService] joinRoom broadcast 수신됨!")
                broadcastRoom = room
            }
        }
        defer { broadcastListener.cancel() }
        
        // 연결 상태 확인
        if !isConnected {
            print("⚠️ [WebSocketService] WebSocket이 연결되지 않음. 재연결 시도...")
            connect()
            
            // 연결 완료까지 최대 5초 대기
            var attempts = 0
            while !isConnected && attempts < 50 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                attempts += 1
            }
            
            if !isConnected {
                print("❌ [WebSocketService] 연결 실패 - 타임아웃")
                throw WebSocketError.notConnected
            }
            
            print("✅ [WebSocketService] 재연결 성공")
        }
        
        print("📤 [WebSocketService] joinRoom 요청 전송 중...")
        
        do {
            // 타임아웃을 10초로 단축
            let room = try await withTimeout(seconds: 10) {
                try await self.sendRequestAsync(.joinRoom,
                                               payload: JoinRoomPayload(roomId: roomId,
                                                                      userName: userName,
                                                                      password: password),
                                               responseType: Room.self)
            }
            print("📥 [WebSocketService] joinRoom 개별 응답 수신 완료")
            return room
        } catch {
            print("⚠️ [WebSocketService] 개별 응답 실패: \(error)")
            
            // 브로드캐스트 폴백 확인
            if let room = broadcastRoom {
                print("✅ [WebSocketService] 브로드캐스트로 성공 처리")
                return room
            }
            
            // 잠시 대기 후 브로드캐스트 재확인
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2초
            if let room = broadcastRoom {
                print("✅ [WebSocketService] 브로드캐스트로 성공 처리 (지연)")
                return room
            }
            
            throw error
        }
    }

    func leaveRoom(roomId: String, playerId: String) async throws -> Room {
        print("📤 [WebSocketService] leaveRoom 호출됨 - roomId: \(roomId), playerId: \(playerId)")
        
        // 🚫 leaveRoom 기능 완전 비활성화 - 뒤로가기 버튼에서만 사용
        print("🚫 [WebSocketService] leaveRoom 비활성화됨 - 뒤로가기 버튼에서만 사용 가능")
        throw NSError(domain: "LeaveRoomDisabled", code: 1001, userInfo: [NSLocalizedDescriptionKey: "leaveRoom이 비활성화되었습니다."])
    }
    
    // 뒤로가기 전용 leaveRoom 메서드
    func leaveRoomForBackButton(roomId: String, playerId: String) async throws -> Room {
        print("🚪 [WebSocketService] 뒤로가기 전용 leaveRoom 호출됨 - roomId: \(roomId), playerId: \(playerId)")
        
        do {
            let room = try await withTimeout(seconds: 5) {
                try await self.sendRequestAsync(.leaveRoom,
                                               payload: LeaveRoomPayload(roomId: roomId,
                                                                       playerId: playerId),
                                               responseType: Room.self)
            }
            print("✅ [WebSocketService] 뒤로가기 leaveRoom 성공")
            return room
        } catch {
            print("⚠️ [WebSocketService] 뒤로가기 leaveRoom 실패: \(error)")
            throw error
        }
    }

    func toggleReady(roomId: String, playerId: String) {
        print("📍 [WebSocketService] toggleReady 호출됨 - roomId: \(roomId), playerId: \(playerId)")
        sendRequest(.toggleReady, payload: ToggleReadyPayload(roomId: roomId,
                                                              playerId: playerId))
    }

    func setRole(roomId: String, playerId: String, role: String?) {
        sendRequest(.setRole, payload: SetRolePayload(roomId: roomId, playerId: playerId, role: role))
    }

    func startGame(roomId: String) {
        sendRequest(.startGame, payload: StartGamePayload(roomId: roomId))
    }
    
    func passBomb(roomId: String, playerId: String) async throws -> Room {
        print("💣 [WebSocketService] passBomb 호출됨 - roomId: \(roomId), playerId: \(playerId)")
        
        do {
            let room = try await withTimeout(seconds: 5) {
                try await self.sendRequestAsync(.passBomb,
                                               payload: PassBombPayload(roomId: roomId,
                                                                       playerId: playerId),
                                               responseType: Room.self)
            }
            print("✅ [WebSocketService] passBomb 성공 - 새 폭탄 소유자: \(room.currentBombHolder ?? "nil")")
            return room
        } catch {
            print("❌ [WebSocketService] passBomb 실패: \(error)")
            throw error
        }
    }
}
