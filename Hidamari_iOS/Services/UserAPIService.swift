import Foundation
import Combine

class UserAPIService {
    static let shared = UserAPIService()
    private var baseURL: URL {
        guard let urlString = ProcessInfo.processInfo.environment["API_BASE_URL"],
              let url = URL(string: urlString) else {
            return URL(string: "http://localhost:8000/api")!
        }
        return url
    }


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

    // ユーザープロフィール取得（GET /api/users/{id}）
    func fetchProfile(userID: String) -> AnyPublisher<User, Error> {
        // 正しいURLパスを構築
        let url = baseURL.appendingPathComponent("users").appendingPathComponent(userID)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // デバッグ用のログ出力
        print("📡 リクエストURL: \(url.absoluteString)")
        
        // 認証トークンを追加
        if let token = AuthTokenManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // デバッグ用にレスポンスの詳細を出力
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 ステータスコード: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode >= 400 {
                        print("⚠️ ユーザー取得失敗（ステータス: \(httpResponse.statusCode)）")
                        if let responseBody = String(data: data, encoding: .utf8) {
                            print("📄 エラーレスポンス: \(responseBody)")
                        }
                    }
                }
                try self.validateResponse(response)
                let userResponse = try self.jsonDecoder.decode(UserResponse.self, from: data)
                return userResponse.data
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
            let encoded = try jsonEncoder.encode(profile)
            request.httpBody = encoded

            if let json = String(data: encoded, encoding: .utf8) {
                print("📤 送信データ: \(json)")
            }
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 ステータスコード: \(httpResponse.statusCode)")
                }

                if let json = String(data: data, encoding: .utf8) {
                    print("📡 レスポンスボディ: \(json)")
                }

                try self.validateResponse(response) // ここで400系で失敗
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
