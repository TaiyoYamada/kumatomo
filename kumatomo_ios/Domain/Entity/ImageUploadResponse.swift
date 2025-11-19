import Foundation


struct ImageUploadResponse: Codable {
    let url: String
    let message: String?

    enum CodingKeys: String, CodingKey {
        case url
        case message
    }
}

struct UserResponse: Codable {
    let data: User

    enum CodingKeys: String, CodingKey {
        case data
    }
}