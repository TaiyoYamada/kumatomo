import Foundation

// MARK: - SearchEndpoint

/// 検索API用エンドポイント定義
enum SearchEndpoint: APIEndpoint {
    case search(query: String, type: SearchFilterType, page: Int, perPage: Int)

    var path: String {
        switch self {
        case .search:
            return "/search"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .search:
            return .get
        }
    }

    var queryParameters: [String: Any]? {
        switch self {
        case let .search(query, type, page, perPage):
            return [
                "q": query,
                "type": type.rawValue,
                "page": page,
                "per_page": perPage
            ]
        }
    }
}
