import Foundation

// MARK: - PaginatedResponse

/// ページネーション付きAPIレスポンスをデコードするための汎用構造体
/// Note: APIClientが.convertFromSnakeCaseを使用するため、CodingKeysは不要
struct PaginatedResponse<T: Decodable>: Decodable {
    let currentPage: Int
    let data: [T]
    let firstPageUrl: String?
    let from: Int?
    let lastPage: Int
    let lastPageUrl: String?
    let nextPageUrl: String?
    let path: String?
    let perPage: Int
    let prevPageUrl: String?
    let to: Int?
    let total: Int
}
