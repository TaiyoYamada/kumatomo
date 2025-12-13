import Combine
import Foundation

// MARK: - APIClient

// Domain層のAPIErrorを使用
// APIError は Domain/Entity/Errors/APIError.swift で定義済み

/// URLSessionベースの共通APIクライアント
final class APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        baseURL = APIConfig.shared.baseURLString
        session = URLSession.shared
        decoder = APIHelper.makeDecoder()
    }

    // MARK: - Public Methods

    /// GETリクエスト
    func get<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        try await request(endpoint)
    }

    /// POSTリクエスト
    func post<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        try await request(endpoint)
    }

    /// PUTリクエスト
    func put<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        try await request(endpoint)
    }

    /// DELETEリクエスト
    func delete(_ endpoint: APIEndpoint) async throws {
        let _: EmptyResponse = try await request(endpoint)
    }

    /// 汎用リクエスト（戻り値あり）
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let urlRequest = try buildURLRequest(endpoint)

        #if DEBUG
        print("📡 \(endpoint.method.rawValue) リクエスト: \(urlRequest.url?.absoluteString ?? "")")
        if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📡 ボディ: \(bodyString)")
        }
        #endif

        let (data, response) = try await performRequest(urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknownError(NSError(
                domain: "APIClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
            ))
        }

        #if DEBUG
        print("📡 ステータスコード: \(httpResponse.statusCode)")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📡 レスポンス: \(jsonString.prefix(500))")
        }
        #endif

        // ステータスコードチェック
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw handleHTTPError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("🚨 デコードエラー: \(decodingError)")
            #endif
            throw APIError.decodingError(decodingError)
        } catch {
            throw APIError.unknownError(error)
        }
    }

    /// 汎用リクエスト（戻り値なし）
    func requestVoid(_ endpoint: APIEndpoint) async throws {
        let urlRequest = try buildURLRequest(endpoint)

        let (data, response) = try await performRequest(urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknownError(NSError(
                domain: "APIClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
            ))
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw handleHTTPError(statusCode: httpResponse.statusCode, data: data)
        }
    }

    // MARK: - Private Methods

    private func buildURLRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        var urlString = baseURL + endpoint.path

        // クエリパラメータを追加
        if let queryParams = endpoint.queryParameters, !queryParams.isEmpty {
            var components = URLComponents(string: urlString)
            components?.queryItems = queryParams.compactMap { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            if let url = components?.url {
                urlString = url.absoluteString
            }
        }

        guard let url = URL(string: urlString) else {
            throw APIError.unknownError(NSError(
                domain: "APIClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"]
            ))
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // ヘッダー設定
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if endpoint.requiresAuth, let token = AuthTokenManager.shared.token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let customHeaders = endpoint.headers {
            for (key, value) in customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // ボディ設定
        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            throw APIError.networkError(urlError)
        } catch {
            throw APIError.unknownError(error)
        }
    }

    private func handleHTTPError(statusCode: Int, data: Data) -> APIError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .rateLimitExceeded
        case 500 ... 599:
            let message = String(data: data, encoding: .utf8) ?? "サーバーエラー"
            return .serverError(message: message)
        default:
            let message = String(data: data, encoding: .utf8) ?? "APIエラー"
            return .apiError(statusCode: statusCode, message: message)
        }
    }
}

// MARK: - EmptyResponse

private struct EmptyResponse: Decodable {}

// MARK: - Convenience Extensions

extension APIClient {
    /// 投稿一覧取得
    func fetchPosts(page: Int? = nil, limit: Int? = nil) async throws -> [Post] {
        try await get(PostEndpoint.fetchAll(page: page, limit: limit))
    }

    /// 投稿詳細取得
    func fetchPost(id: Int) async throws -> Post {
        try await get(PostEndpoint.fetchPost(id: id))
    }

    /// 投稿作成
    func createPost(userId: Int, content: String, imageUrls: [String] = [], tags: [String] = []) async throws -> Post {
        try await post(PostEndpoint.create(userId: userId, content: content, imageUrls: imageUrls, tags: tags))
    }
}
