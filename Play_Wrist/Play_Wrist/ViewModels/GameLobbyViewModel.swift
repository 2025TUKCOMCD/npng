import Foundation

class GameLobbyViewModel: ObservableObject {
    @Published var bombHolderId: Int?
    @Published var roleAssignments: [Int: String] = [:]
    @Published var location: String?

    let baseURL = "http://15.164.50.19:8000"

    // 🔸 Bomb Holder 이름 반환
    func assignBomb(roomId: Int, idToken: String?, completion: @escaping (String?) -> Void) {
        guard let token = idToken,
              let url = URL(string: "\(baseURL)/rooms/\(roomId)/assign-bomb") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let result = try? JSONDecoder().decode(BombAssignResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.bombHolderId = result.bomb_holder_id
                    completion(result.bomb_holder_name)
                }
            } else {
                completion(nil)
            }
        }.resume()
    }

    // 🔸 SpyFall 역할 할당
    func assignSpyFallRoles(roomId: Int, idToken: String?, completion: @escaping ([SpyFallRoleResult]) -> Void) {
        guard let token = idToken,
              let url = URL(string: "\(baseURL)/rooms/\(roomId)/assign-roles") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let result = try? JSONDecoder().decode(SpyFallAssignResponse.self, from: data) {
                DispatchQueue.main.async {
                    completion(result.results)
                }
            }
        }.resume()
    }
}

// MARK: - 서버 응답 모델들

struct BombAssignResponse: Codable {
    let bomb_holder_id: Int
    let bomb_holder_name: String
}

struct SpyFallAssignResponse: Codable {
    let results: [SpyFallRoleResult]
}

struct SpyFallRoleResult: Codable {
    let userId: Int
    let userName: String
    let role: String
    let location: String
    let citizenRole: String?
}
