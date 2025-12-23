import Foundation

// MARK: - SearchAPIService

/// APIClient経由の検索APIサービス
class SearchAPIService {
    static let shared = SearchAPIService()

    private let client = APIClient.shared
    private let logger = AppLogger.network

    private init() {}

    /// 統合検索を実行する
    func search(
        query: String,
        type: SearchFilterType = .all,
        page: Int = 1,
        perPage: Int = 10
    ) async throws -> (SearchResult, String, SearchFilterType) {
        logger.debug("検索リクエスト: query=\(query), type=\(type.rawValue), page=\(page)")

        do {
            let response: SearchAPIResponse = try await client.get(
                SearchEndpoint.search(query: query, type: type, page: page, perPage: perPage)
            )
            return (response.data, response.query, SearchFilterType(rawValue: response.type) ?? .all)
        } catch let apiError as APIError {
            logger.logError(apiError, context: "Search")
            throw apiError
        } catch {
            logger.logError(error, context: "Search")
            throw APIError.networkError(error)
        }
    }
}

// MARK: - SearchAPIResponse

private struct SearchAPIResponse: Codable {
    let data: SearchResult
    let query: String
    let type: String
}
