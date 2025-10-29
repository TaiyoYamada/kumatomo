import Foundation

struct ShopListResponse: Codable {
    let data: [Shop]
    let pagination: ShopPagination?
}

// Pagination for shops with all fields optional (robust to API variations)
struct ShopPagination: Codable {
    let currentPage: Int?
    let lastPage: Int?
    let perPage: Int?
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case lastPage = "last_page"
        case perPage = "per_page"
        case total
    }
}
