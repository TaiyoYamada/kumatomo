import Foundation

// MARK: - ImageUploadResponse

struct ImageUploadResponse: Codable {
    let url: String
    let message: String?

    enum CodingKeys: String, CodingKey {
        case url
        case message
    }
}

// MARK: - UserResponse

struct UserResponse: Codable {
    let data: User

    enum CodingKeys: String, CodingKey {
        case data
    }
}
