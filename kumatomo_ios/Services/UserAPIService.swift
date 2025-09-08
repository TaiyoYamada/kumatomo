import Foundation
import Combine
import UIKit

// MARK: - API Response Models
struct UsernameAvailabilityResponse: Codable {
    let available: Bool
    let message: String?
}

class UserAPIService {
    static let shared = UserAPIService()
    private var baseURL: URL {
        guard let urlString = ProcessInfo.processInfo.environment["API_BASE_URL"],
              let url = URL(string: urlString) else {
            // Development default - HTTP direct to Laravel
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

        return APISession.shared.session.dataTaskPublisher(for: request)
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

        return APISession.shared.session.dataTaskPublisher(for: request)
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

        return APISession.shared.session.dataTaskPublisher(for: request)
            .tryMap { _, response in
                try self.validateResponse(response)
                return true
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Profile Update Methods
    
    /// Updates user profile information
    func updateProfile(_ user: User) -> AnyPublisher<User, Error> {
        let url = baseURL.appendingPathComponent("users").appendingPathComponent("\(user.id)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication token
        if let token = AuthTokenManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let encoded = try jsonEncoder.encode(user)
            request.httpBody = encoded
            
            if let json = String(data: encoded, encoding: .utf8) {
                print("📤 プロフィール更新データ: \(json)")
            }
        } catch {
            return Fail(error: ProfileError.profileUpdateFailed(error)).eraseToAnyPublisher()
        }
        
        return APISession.shared.session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 プロフィール更新ステータス: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 401 {
                        throw ProfileError.unauthorized
                    } else if httpResponse.statusCode >= 400 {
                        let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    }
                }
                
                try self.validateResponse(response)
                let userResponse = try self.jsonDecoder.decode(UserResponse.self, from: data)
                return userResponse.data
            }
            .mapError { error in
                if error is ProfileError {
                    return error
                }
                return ProfileError.profileUpdateFailed(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Checks if a username is available
    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, Error> {
        let url = baseURL.appendingPathComponent("users/check-username")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication token
        if let token = AuthTokenManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = ["username": username]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: ProfileError.usernameCheckFailed(error)).eraseToAnyPublisher()
        }
        
        print("📡 ユーザーネーム確認: \(username)")
        
        return APISession.shared.session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 ユーザーネーム確認ステータス: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 401 {
                        throw ProfileError.unauthorized
                    } else if httpResponse.statusCode >= 400 {
                        let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    }
                }
                
                try self.validateResponse(response)
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let available = json["available"] as? Bool {
                    return available
                } else {
                    throw ProfileError.usernameCheckFailed(APIError.invalidResponse)
                }
            }
            .mapError { error in
                if error is ProfileError {
                    return error
                }
                return ProfileError.usernameCheckFailed(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Uploads profile image and returns the image URL
    func uploadProfileImage(_ image: UIImage) -> AnyPublisher<String, Error> {
        return uploadImage(image, endpoint: "/upload-profile-image")
            .mapError { error in
                ProfileError.imageUploadFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
    /// Uploads cover image and returns the image URL
    func uploadCoverImage(_ image: UIImage) -> AnyPublisher<String, Error> {
        return uploadImage(image, endpoint: "/upload-cover-image")
            .mapError { error in
                ProfileError.imageUploadFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Image Upload Helper
    
    private func uploadImage(_ image: UIImage, endpoint: String) -> AnyPublisher<String, Error> {
        let url = baseURL.appendingPathComponent(endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            return Fail(error: ImageUploadError.imageConversionFailed).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authentication token
        if let token = AuthTokenManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("🖼️ 画像アップロード開始: \(endpoint)")
        print("📡 画像データサイズ: \(imageData.count) bytes")
        
        return APISession.shared.session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 画像アップロードステータス: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 401 {
                        throw ProfileError.unauthorized
                    } else if httpResponse.statusCode >= 400 {
                        let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    }
                }
                
                try self.validateResponse(response)
                
                let decoder = JSONDecoder()
                let response = try decoder.decode(ImageUploadResponse.self, from: data)
                print("✅ 画像アップロード成功: \(response.url)")
                return response.url
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
