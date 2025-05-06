import Foundation
import Combine

class UserAPIService {
    static let shared = UserAPIService()
    private let baseURL = URL(string: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://10.33.2.4:8000/api")!

    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    // 🔹 ユーザープロフィール取得（GET /api/users/{id}）
    func fetchProfile(userID: String) -> AnyPublisher<User, Error> {
        let url = baseURL.appendingPathComponent(userID)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                try self.validateResponse(response)
                return try self.jsonDecoder.decode(User.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // 🔹 ユーザープロフィール保存（POST /api/users）
    func saveProfile(_ profile: User) -> AnyPublisher<Bool, Error> {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try jsonEncoder.encode(profile)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { _, response in
                try self.validateResponse(response)
                return true
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // 🔹 新規ユーザー登録（POST /api/users）
    func createUser(_ user: User) -> AnyPublisher<Bool, Error> {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try jsonEncoder.encode(user)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { _, response in
                try self.validateResponse(response)
                return true
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // 🔸 HTTP ステータスコード確認（共通）
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}
