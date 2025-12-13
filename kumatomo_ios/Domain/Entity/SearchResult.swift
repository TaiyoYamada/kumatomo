import Foundation

// MARK: - SearchResult

// 検索結果のモデル
struct SearchResult: Codable {
    let posts: [Post]
    let pagination: SearchPagination

    enum CodingKeys: String, CodingKey {
        case posts, pagination
    }
}

// MARK: - SearchPagination

// 検索のページネーション情報
struct SearchPagination: Codable {
    let currentPage: Int
    let perPage: Int
    let posts: PaginationInfo?

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case perPage = "per_page"
        case posts
    }
}

// MARK: - PaginationInfo

// ページネーション詳細情報
struct PaginationInfo: Codable {
    let currentPage: Int
    let lastPage: Int
    let perPage: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case lastPage = "last_page"
        case perPage = "per_page"
        case total
    }
}

// MARK: - SearchHistory

// 検索履歴のモデル
struct SearchHistory: Identifiable, Codable {
    let id = UUID()
    let query: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case query, timestamp
    }
}
