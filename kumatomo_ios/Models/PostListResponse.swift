import Foundation

struct PostListResponse: Codable {
    let currentPage: Int?
    let data: [Post]
    let lastPage: Int?
    let perPage: Int?
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case data
        case lastPage = "last_page"
        case perPage = "per_page"
        case total
    }
}

