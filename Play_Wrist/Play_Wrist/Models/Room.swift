import Foundation

// MARK: - Room 모델
struct Room: Codable, Identifiable {
    let id: Int
    let title: String
    let game: String
    let password: String
    let maxPlayers: Int
    let hostName: String
    var players: [String]
}

// MARK: - APIService 싱글톤
final class APIService {
    static let shared = APIService()
    private init() {}

    let baseURL = "http://43.201.195.113:8000"

    // ✅ 방 목록 조회
    func fetchRooms(completion: @escaping ([Room]) -> Void) {
        guard let url = URL(string: "\(baseURL)/rooms") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let decoded = try? JSONDecoder().decode([Room].self, from: data) else { return }
            DispatchQueue.main.async {
                completion(decoded)
            }
        }.resume()
    }

    // ✅ 방 생성
    func createRoom(_ room: Room, completion: @escaping (Room?) -> Void) {
        guard let url = URL(string: "\(baseURL)/rooms/create") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let body = try? JSONEncoder().encode(room) else { return }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let createdRoom = try? JSONDecoder().decode(Room.self, from: data) else {
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                completion(createdRoom)
            }
        }.resume()
    }

    // ✅ 방 입장
    func joinRoom(roomID: Int, userName: String, password: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/rooms/\(roomID)/join") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "user_name": userName,
            "password": password
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }
            DispatchQueue.main.async {
                completion(httpResponse.statusCode == 200)
            }
        }.resume()
    }

    // ✅ 게임 시작
    func startGame(roomId: Int, idToken: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/rooms/\(roomId)/start") else {
            print("🚫 잘못된 URL입니다.")
            completion(false)
            return
        }

        print("📡 [startGame] 요청 준비 완료 - roomId: \(roomId)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [startGame] 요청 실패: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("⚠️ [startGame] 유효하지 않은 응답")
                completion(false)
                return
            }

            print("📬 [startGame] 응답 상태 코드: \(httpResponse.statusCode)")

            if let data = data, let bodyString = String(data: data, encoding: .utf8) {
                print("📦 [startGame] 응답 본문: \(bodyString)")
            }

            if httpResponse.statusCode == 200 {
                print("✅ [startGame] 게임 시작 성공")
                completion(true)
            } else {
                print("⚠️ [startGame] 게임 시작 실패 - 상태 코드: \(httpResponse.statusCode)")
                completion(false)
            }
        }.resume()
    }
}
