import Alamofire
import Combine
import Foundation

// MARK: - APIClient

// Domain層のAPIErrorを使用
// APIError は Domain/Entity/Errors/APIError.swift で定義済み

/// Alamofireベースの共通APIクライアント
final class APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: Session
    private let decoder: JSONDecoder

    private init() {
        baseURL = APIConfig.shared.baseURLString
        session = Session.default
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
        let urlString = buildURL(endpoint)

        #if DEBUG
        print("📡 \(endpoint.method.rawValue) リクエスト: \(urlString)")
        #endif

        let headers = buildHeaders(endpoint)
        let method = alamofireMethod(endpoint.method)

        let dataRequest: DataRequest

        if let body = endpoint.body {
            #if DEBUG
            print("📡 ボディ: \(body)")
            #endif
            dataRequest = session.request(
                urlString,
                method: method,
                parameters: body,
                encoding: JSONEncoding.default,
                headers: headers
            )
        } else if let queryParams = endpoint.queryParameters {
            dataRequest = session.request(
                urlString,
                method: method,
                parameters: queryParams,
                encoding: URLEncoding.default,
                headers: headers
            )
        } else {
            dataRequest = session.request(
                urlString,
                method: method,
                headers: headers
            )
        }

        let response = await dataRequest
            .validate(statusCode: 200 ... 299)
            .serializingData()
            .response

        #if DEBUG
        print("📡 ステータスコード: \(response.response?.statusCode ?? 0)")
        if let data = response.data, let jsonString = String(data: data, encoding: .utf8) {
            print("📡 レスポンス: \(jsonString.prefix(500))")
        }
        #endif

        switch response.result {
        case let .success(data):
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

        case let .failure(afError):
            throw handleAlamofireError(afError, response: response.response, data: response.data)
        }
    }

    /// 汎用リクエスト（戻り値なし）
    func requestVoid(_ endpoint: APIEndpoint) async throws {
        let urlString = buildURL(endpoint)
        let headers = buildHeaders(endpoint)
        let method = alamofireMethod(endpoint.method)

        let dataRequest: DataRequest = if let body = endpoint.body {
            session.request(
                urlString,
                method: method,
                parameters: body,
                encoding: JSONEncoding.default,
                headers: headers
            )
        } else {
            session.request(
                urlString,
                method: method,
                headers: headers
            )
        }

        let response = await dataRequest
            .validate(statusCode: 200 ... 299)
            .serializingData()
            .response

        if case let .failure(afError) = response.result {
            throw handleAlamofireError(afError, response: response.response, data: response.data)
        }
    }

    // MARK: - Private Methods

    private func buildURL(_ endpoint: APIEndpoint) -> String {
        baseURL + endpoint.path
    }

    private func buildHeaders(_ endpoint: APIEndpoint) -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(.accept("application/json"))
        headers.add(.contentType("application/json"))

        if endpoint.requiresAuth, let token = AuthTokenManager.shared.token, !token.isEmpty {
            headers.add(.authorization(bearerToken: token))
        }

        if let customHeaders = endpoint.headers {
            for (key, value) in customHeaders {
                headers.add(name: key, value: value)
            }
        }

        return headers
    }

    private func alamofireMethod(_ method: HTTPMethod) -> Alamofire.HTTPMethod {
        switch method {
        case .get: return .get
        case .post: return .post
        case .put: return .put
        case .patch: return .patch
        case .delete: return .delete
        }
    }

    private func handleAlamofireError(
        _ afError: AFError,
        response: HTTPURLResponse?,
        data: Data?
    ) -> APIError {
        // ステータスコードに基づくエラー変換
        if let statusCode = response?.statusCode {
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
                let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "サーバーエラー"
                return .serverError(message: message)
            default:
                let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "APIエラー"
                return .apiError(statusCode: statusCode, message: message)
            }
        }

        // ネットワークエラー
        if case let .sessionTaskFailed(error) = afError {
            return .networkError(error)
        }

        return .unknownError(afError)
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
