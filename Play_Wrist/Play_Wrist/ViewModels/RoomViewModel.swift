import Foundation
import Combine

@MainActor
final class RoomViewModel: ObservableObject {
    // 현재 선택된/입장한 방
    @Published var room: Room? = nil

    // 전체 방 목록 (필요하면 사용)
    @Published var rooms: [Room] = []

    // 마지막 에러(간단한 UI용)
    @Published var lastError: String? = nil

    private var bag = Set<AnyCancellable>()

    init() {
        // WebSocket 연결 시도 (앱 시작 또는 뷰모델 생성 시 한 번만)
        WebSocketService.shared.connect()

        // 서버 푸시 구독 — 기존 코드와 동일
        WebSocketService.shared.roomsSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] rooms in
                self?.rooms = rooms
            })
            .store(in: &bag)

        WebSocketService.shared.joinedRoomSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] room in
                self?.room = room
            })
            .store(in: &bag)

        WebSocketService.shared.playerUpdatedSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] updated in
                guard let self = self else { return }
                if self.room?.id == updated.id { self.room = updated }
                if let idx = self.rooms.firstIndex(where: { $0.id == updated.id }) {
                    self.rooms[idx] = updated
                }
            })
            .store(in: &bag)
    }

    // MARK: - Helper: 짧게 대기 (최대 timeout 초)
    // 주의: WebSocketService 내부 연결 상태를 직접 확인하지 않으므로
    // "조금 기다린 후 요청" 방식으로 안정성을 높입니다.
    private func shortWait(timeout: TimeInterval = 3.0, step: UInt64 = 200_000_000) async {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            // 0.2s 기본
            try? await Task.sleep(nanoseconds: step)
        }
    }

    // MARK: - 방 생성
    func createRoom(title: String, game: String, password: String, maxPlayers: Int, hostName: String) {
        // 즉시 UI에 임시로 보일 수 있는 draft room (옵션)
        let host = Player(
            id: UUID().uuidString,
            name: hostName,
            isReady: true,
            role: nil,
            isHost: true
        )

        let draft = Room(
            id: UUID().uuidString,
            title: title,
            game: game,
            password: password,
            maxPlayers: maxPlayers,
            hostName: hostName,
            players: [host]
        )

        // 비동기 작업: 요청 전 잠깐 대기(최대 3초) — 최소 변경 전략
        Task {
            await shortWait(timeout: 3.0)

            do {
                let created = try await WebSocketService.shared.createRoom(draft)
                // UI 업데이트는 MainActor(이 클래스가 @MainActor이므로 안전)
                self.room = created
                if let idx = self.rooms.firstIndex(where: { $0.id == created.id }) {
                    self.rooms[idx] = created
                } else {
                    self.rooms.append(created)
                }
                self.lastError = nil
            } catch {
                // 실패 시 로깅 및 간단한 에러 상태 저장
                print("createRoom error:", error)
                self.lastError = "방 생성 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - 방 목록 조회 (예시)
    func fetchRooms() {
        Task {
            await shortWait(timeout: 1.0) // 목록 조회는 짧게 대기
            do {
                let list = try await WebSocketService.shared.fetchRooms()
                self.rooms = list
                self.lastError = nil
            } catch {
                print("fetchRooms error:", error)
                self.lastError = "방 목록 불러오기 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - 방 입장 (예시)
    func joinRoom(roomId: String, userName: String, password: String?) {
        Task {
            await shortWait(timeout: 2.0)
            do {
                let joined = try await WebSocketService.shared.joinRoom(roomId: roomId, userName: userName, password: password ?? "")
                self.room = joined
                self.lastError = nil
            } catch {
                print("joinRoom error:", error)
                self.lastError = "방 입장 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - 준비 토글 (예시)
    func toggleReady(roomId: String, playerId: String) {
        Task {
            await shortWait(timeout: 1.0)
            do {
                let updated = try await WebSocketService.shared.toggleReady(roomId: roomId, playerId: playerId)
                // 서버에서 playerUpdated push를 보낼 가능성이 있으므로 그걸로 UI가 갱신될 수 있음.
                // 그래도 즉시 반영하려면:
                if self.room?.id == updated.id { self.room = updated }
                if let idx = self.rooms.firstIndex(where: { $0.id == updated.id }) {
                    self.rooms[idx] = updated
                }
                self.lastError = nil
            } catch {
                print("toggleReady error:", error)
                self.lastError = "준비 토글 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - 역할 설정 (예시)
    func setRole(roomId: String, playerId: String, role: String?) {
        Task {
            await shortWait(timeout: 1.0)
            do {
                let updated = try await WebSocketService.shared.setRole(roomId: roomId, playerId: playerId, role: role)
                if self.room?.id == updated.id { self.room = updated }
                if let idx = self.rooms.firstIndex(where: { $0.id == updated.id }) {
                    self.rooms[idx] = updated
                }
                self.lastError = nil
            } catch {
                print("setRole error:", error)
                self.lastError = "역할 설정 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - 게임 시작 (예시)
    func startGame(roomId: String, idToken: String) {
        Task {
            await shortWait(timeout: 1.0)
            do {
                let ok = try await WebSocketService.shared.startGame(roomId: roomId, idToken: idToken)
                if !ok {
                    self.lastError = "게임 시작 요청이 거부되었습니다."
                } else {
                    self.lastError = nil
                }
            } catch {
                print("startGame error:", error)
                self.lastError = "게임 시작 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - 클린업 (필요하면 호출)
    func disconnectWebSocket() {
        WebSocketService.shared.disconnect()
    }
}
