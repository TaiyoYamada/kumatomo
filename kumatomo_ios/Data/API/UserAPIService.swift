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
    private var baseURL: URL? { APIConfig.shared.baseURL }


    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
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
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
        let url = baseURL.appendingPathComponent("users").appendingPathComponent(userID)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        
        // キャッシュを完全に無視して、必ずサーバーから新しい情報を取得するようにする
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // さらに強力なキャッシュ無効化ヘッダーを追加
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("0", forHTTPHeaderField: "Expires")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        // --- 👆 ここまで修正！ ---
        
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

                    // レスポンスボディを文字列として出力
                    if let responseBody = String(data: data, encoding: .utf8) {
                        print("📄 レスポンスボディ: \(responseBody)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        print("⚠️ ユーザー取得失敗（ステータス: \(httpResponse.statusCode)）")
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
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
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
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
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
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
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
    
    /// Updates user's username
    func updateUsername(_ username: String) -> AnyPublisher<User, Error> {
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
        let url = baseURL.appendingPathComponent("users/update-username")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
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
            return Fail(error: ProfileError.profileUpdateFailed(error)).eraseToAnyPublisher()
        }
        
        print("📡 ユーザーネーム更新: \(username)")
        
        return APISession.shared.session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 ユーザーネーム更新ステータス: \(httpResponse.statusCode)")
                    
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
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
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
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
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

    // MARK: - Enhanced CRUD Operations
    
    /// Creates a new user profile with comprehensive error handling and progress tracking
    @MainActor
    func createProfile(_ user: User, progressTracker: ProgressTracker? = nil) -> AnyPublisher<User, Error> {
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
        let url = baseURL.appendingPathComponent("users")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication token if available
        if let token = AuthTokenManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Convert user to create request
        let createRequest = user.toCreateRequest()
        
        do {
            let encoded = try jsonEncoder.encode(createRequest)
            request.httpBody = encoded
            
            if let json = String(data: encoded, encoding: .utf8) {
                print("📤 プロフィール作成データ: \(json)")
            }
        } catch {
            return Fail(error: ProfileError.validationFailed(["データのエンコードに失敗しました"]))
                .eraseToAnyPublisher()
        }
        
        progressTracker?.start()
        
        let publisher = APISession.shared.session.dataTaskPublisher(for: request)
            .handleEvents(
                receiveSubscription: { _ in
                    progressTracker?.update(progress: 0.1)
                },
                receiveOutput: { _ in
                    progressTracker?.update(progress: 0.8)
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        progressTracker?.complete()
                    case .failure:
                        progressTracker?.cancel()
                    }
                }
            )
            .tryMap { data, response in
                progressTracker?.update(progress: 0.6)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 プロフィール作成ステータス: \(httpResponse.statusCode)")
                    
                    switch httpResponse.statusCode {
                    case 401:
                        throw ProfileError.unauthorized
                    case 422:
                        // Parse validation errors
                        if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errors = errorData["errors"] as? [String: [String]] {
                            let messages = errors.values.flatMap { $0 }
                            throw ProfileError.validationFailed(messages)
                        }
                        throw ProfileError.validationFailed(["入力データが無効です"])
                    case 409:
                        throw ProfileError.usernameNotAvailable
                    case 400..<500:
                        let message = String(data: data, encoding: .utf8) ?? "クライアントエラー"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    case 500...:
                        let message = String(data: data, encoding: .utf8) ?? "サーバーエラー"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    default:
                        break
                    }
                }
                
                try self.validateResponse(response)
                let userResponse = try self.jsonDecoder.decode(UserResponse.self, from: data)
                print("✅ プロフィール作成成功: \(userResponse.data.username ?? "unknown")")
                return userResponse.data
            }
            .mapError { error in
                if error is ProfileError {
                    return error
                }
                return ProfileError.networkError(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        // Set up cancellation support
        if let tracker = progressTracker {
            let cancellable = AnyCancellable(publisher.sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            ))
            tracker.setCancellable(cancellable)
        }
        
        return publisher
    }
    
    /// Enhanced profile fetching with caching and offline support
    func fetchProfileEnhanced(userID: String, useCache: Bool = true) -> AnyPublisher<User, Error> {
        // Check cache first if requested
        if useCache, let cachedUser = ProfileCache.shared.getUser(id: userID) {
            print("📱 キャッシュからプロフィール取得: \(userID)")
            return Just(cachedUser)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
        
        let url = baseURL.appendingPathComponent("users").appendingPathComponent(userID)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication token
        if let token = AuthTokenManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📡 プロフィール取得リクエスト: \(url.absoluteString)")
        
        return APISession.shared.session.dataTaskPublisher(for: request)
            .retry(2) // Automatic retry for network issues
            .tryMap { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 プロフィール取得ステータス: \(httpResponse.statusCode)")
                    
                    switch httpResponse.statusCode {
                    case 401:
                        throw ProfileError.unauthorized
                    case 404:
                        throw ProfileError.profileLoadFailed(APIError.userNotFound)
                    case 400..<500:
                        let message = String(data: data, encoding: .utf8) ?? "クライアントエラー"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    case 500...:
                        let message = String(data: data, encoding: .utf8) ?? "サーバーエラー"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    default:
                        break
                    }
                }
                
                try self.validateResponse(response)
                let userResponse = try self.jsonDecoder.decode(UserResponse.self, from: data)
                
                // Cache the result
                ProfileCache.shared.setUser(userResponse.data)
                
                return userResponse.data
            }
            .mapError { error in
                if error is ProfileError {
                    return error
                }
                return ProfileError.profileLoadFailed(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Deletes a user profile with confirmation and cleanup
    @MainActor
    func deleteProfile(userID: String, progressTracker: ProgressTracker? = nil) -> AnyPublisher<Bool, Error> {
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
        let url = baseURL.appendingPathComponent("users").appendingPathComponent(userID)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication token
        if let token = AuthTokenManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🗑️ プロフィール削除リクエスト: \(userID)")
        progressTracker?.start()
        
        let publisher = APISession.shared.session.dataTaskPublisher(for: request)
            .handleEvents(
                receiveSubscription: { _ in
                    progressTracker?.update(progress: 0.1)
                },
                receiveOutput: { _ in
                    progressTracker?.update(progress: 0.8)
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        progressTracker?.complete()
                    case .failure:
                        progressTracker?.cancel()
                    }
                }
            )
            .tryMap { data, response in
                progressTracker?.update(progress: 0.6)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 プロフィール削除ステータス: \(httpResponse.statusCode)")
                    
                    switch httpResponse.statusCode {
                    case 401:
                        throw ProfileError.unauthorized
                    case 403:
                        throw ProfileError.serverError(statusCode: 403, message: "削除権限がありません")
                    case 404:
                        throw ProfileError.profileLoadFailed(APIError.userNotFound)
                    case 400..<500:
                        let message = String(data: data, encoding: .utf8) ?? "削除に失敗しました"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    case 500...:
                        let message = String(data: data, encoding: .utf8) ?? "サーバーエラー"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    default:
                        break
                    }
                }
                
                try self.validateResponse(response)
                
                // Clean up local cache
                ProfileCache.shared.removeUser(id: userID)
                
                print("✅ プロフィール削除成功: \(userID)")
                return true
            }
            .mapError { error in
                if error is ProfileError {
                    return error
                }
                return ProfileError.networkError(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        // Set up cancellation support
        if let tracker = progressTracker {
            let cancellable = AnyCancellable(publisher.sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            ))
            tracker.setCancellable(cancellable)
        }
        
        return publisher
    }
    
    /// Enhanced image upload with progress tracking and validation
    @MainActor
    func uploadImageEnhanced(_ image: UIImage, endpoint: String, progressTracker: ProgressTracker? = nil) -> AnyPublisher<String, Error> {
        // Validate image before upload
        guard let validationResult = validateImageForUpload(image) else {
            return Fail(error: ProfileError.imageUploadFailed(ImageUploadError.imageConversionFailed))
                .eraseToAnyPublisher()
        }
        
        if case .failure(let error) = validationResult {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        guard let baseURL else { return Fail(error: APIError.invalidURL).eraseToAnyPublisher() }
        let url = baseURL.appendingPathComponent(endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            return Fail(error: ProfileError.imageUploadFailed(ImageUploadError.imageConversionFailed))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60.0 // 60 second timeout for uploads
        
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
        
        progressTracker?.start()
        
        let publisher = APISession.shared.session.dataTaskPublisher(for: request)
            .handleEvents(
                receiveSubscription: { _ in
                    progressTracker?.update(progress: 0.1)
                },
                receiveOutput: { _ in
                    progressTracker?.update(progress: 0.9)
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        progressTracker?.complete()
                    case .failure:
                        progressTracker?.cancel()
                    }
                }
            )
            .tryMap { data, response in
                progressTracker?.update(progress: 0.7)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 画像アップロードステータス: \(httpResponse.statusCode)")
                    
                    switch httpResponse.statusCode {
                    case 401:
                        throw ProfileError.unauthorized
                    case 413:
                        throw ProfileError.imageTooLarge(maxSize: 10)
                    case 415:
                        throw ProfileError.unsupportedImageFormat
                    case 429:
                        throw ProfileError.rateLimitExceeded
                    case 507:
                        throw ProfileError.quotaExceeded
                    case 400..<500:
                        let message = String(data: data, encoding: .utf8) ?? "画像アップロードエラー"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    case 500...:
                        let message = String(data: data, encoding: .utf8) ?? "サーバーエラー"
                        throw ProfileError.serverError(statusCode: httpResponse.statusCode, message: message)
                    default:
                        break
                    }
                }
                
                try self.validateResponse(response)
                
                let decoder = JSONDecoder()
                let response = try decoder.decode(ImageUploadResponse.self, from: data)
                print("✅ 画像アップロード成功: \(response.url)")
                return response.url
            }
            .mapError { error in
                if error is ProfileError {
                    return error
                }
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    return ProfileError.uploadTimeout
                }
                return ProfileError.imageUploadFailed(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        // Set up cancellation support
        if let tracker = progressTracker {
            let cancellable = AnyCancellable(publisher.sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            ))
            tracker.setCancellable(cancellable)
        }
        
        return publisher
    }
    
    // MARK: - Enhanced Image Upload Methods
    
    /// Enhanced profile image upload with progress tracking
    @MainActor
    func uploadProfileImageEnhanced(_ image: UIImage, progressTracker: ProgressTracker? = nil) -> AnyPublisher<String, Error> {
        return uploadImageEnhanced(image, endpoint: "/upload-profile-image", progressTracker: progressTracker)
    }
    
    /// Enhanced cover image upload with progress tracking
    @MainActor
    func uploadCoverImageEnhanced(_ image: UIImage, progressTracker: ProgressTracker? = nil) -> AnyPublisher<String, Error> {
        return uploadImageEnhanced(image, endpoint: "/upload-cover-image", progressTracker: progressTracker)
    }
    
    // MARK: - Private Helper Methods
    
    private func validateImageForUpload(_ image: UIImage) -> Result<Void, ProfileError>? {
        // Check image dimensions
        let maxDimension: CGFloat = 4096
        if image.size.width > maxDimension || image.size.height > maxDimension {
            return .failure(.imageTooLarge(maxSize: 10))
        }
        
        // Check if image can be converted to JPEG
        guard image.jpegData(compressionQuality: 0.7) != nil else {
            return .failure(.imageCompressionFailed)
        }
        
        return .success(())
    }
    
    // 🔸 HTTP ステータスコード確認（共通）
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - Async/Await Convenience
extension UserAPIService {
    /// Async API for fetching a user profile
    func fetchProfileAsync(userID: String) async throws -> User {
        guard let baseURL else { throw APIError.invalidURL }
        let url = baseURL.appendingPathComponent("users").appendingPathComponent(userID)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = AuthTokenManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // キャッシュを完全に無視して、必ずサーバーから新しい情報を取得するようにする
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("0", forHTTPHeaderField: "Expires")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
        let (data, response) = try await APISession.shared.session.data(for: request)
        try validateResponse(response)
        let userResponse = try jsonDecoder.decode(UserResponse.self, from: data)
        return userResponse.data
    }
}
