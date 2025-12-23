import Alamofire
import Foundation

// MARK: - APIClient

// Domain層のAPIErrorを使用
// APIError は Domain/Entity/Errors/APIError.swift で定義済み

/// AlamofireベースのAPIクライアント
final class APIClient: @unchecked Sendable {
    static let shared = APIClient()

    private let baseURL: String
    private let session: Session
    private let decoder: JSONDecoder
    private let logger = AppLogger.network

    private init() {
        baseURL = APIConfig.shared.baseURLString
        decoder = APIHelper.makeDecoder()

        // localhost用TrustManager設定（開発用）
        let evaluators: [String: ServerTrustEvaluating] = [
            "localhost": DisabledTrustEvaluator()
        ]
        let manager = ServerTrustManager(allHostsMustBeEvaluated: false, evaluators: evaluators)
        session = Session(serverTrustManager: manager)
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
        let url = baseURL + endpoint.path
        let method = httpMethod(from: endpoint.method)

        var headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]

        if endpoint.requiresAuth, let token = AuthTokenManager.shared.token, !token.isEmpty {
            headers.add(.authorization(bearerToken: token))
        }

        if let customHeaders = endpoint.headers {
            for (key, value) in customHeaders {
                headers.add(name: key, value: value)
            }
        }

        logger.logRequest(method: endpoint.method.rawValue, url: url, body: endpoint.body)

        let dataRequest: DataRequest
        if let queryParams = endpoint.queryParameters, !queryParams.isEmpty {
            let stringParams = queryParams.mapValues { "\($0)" }
            dataRequest = session.request(
                url,
                method: method,
                parameters: stringParams,
                encoding: URLEncoding.queryString,
                headers: headers
            )
        } else if let body = endpoint.body {
            dataRequest = session.request(
                url,
                method: method,
                parameters: body,
                encoding: JSONEncoding.default,
                headers: headers
            )
        } else {
            dataRequest = session.request(url, method: method, headers: headers)
        }

        let response = await dataRequest
            .validate(statusCode: 200 ..< 300)
            .serializingData()
            .response

        logger.logResponse(
            statusCode: response.response?.statusCode ?? -1,
            url: url,
            body: response.data.flatMap { String(data: $0, encoding: .utf8) }
        )

        switch response.result {
        case let .success(data):
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch let decodingError as DecodingError {
                logger.logError(decodingError, context: "Decode")
                throw APIError.decodingError(decodingError)
            } catch {
                throw APIError.unknownError(error)
            }
        case let .failure(afError):
            throw handleAlamofireError(afError, data: response.data)
        }
    }

    /// 汎用リクエスト（戻り値なし）
    func requestVoid(_ endpoint: APIEndpoint) async throws {
        let url = baseURL + endpoint.path
        let method = httpMethod(from: endpoint.method)

        var headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]

        if endpoint.requiresAuth, let token = AuthTokenManager.shared.token, !token.isEmpty {
            headers.add(.authorization(bearerToken: token))
        }

        let dataRequest: DataRequest = if let body = endpoint.body {
            session.request(
                url,
                method: method,
                parameters: body,
                encoding: JSONEncoding.default,
                headers: headers
            )
        } else {
            session.request(url, method: method, headers: headers)
        }

        let response = await dataRequest
            .validate(statusCode: 200 ..< 300)
            .serializingData()
            .response

        if case let .failure(afError) = response.result {
            throw handleAlamofireError(afError, data: response.data)
        }
    }

    // MARK: - Private Methods

    private func httpMethod(from method: HTTPMethod) -> Alamofire.HTTPMethod {
        switch method {
        case .get: return .get
        case .post: return .post
        case .put: return .put
        case .patch: return .patch
        case .delete: return .delete
        }
    }

    private func handleAlamofireError(_ error: AFError, data: Data?) -> APIError {
        if let statusCode = error.responseCode {
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

        // ネットワークエラーの場合
        if let urlError = error.underlyingError as? URLError {
            return .networkError(urlError)
        }

        return .unknownError(error)
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
