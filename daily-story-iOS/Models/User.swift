import Foundation

/// ユーザーモデル
struct User: Codable, Identifiable {
    var id: Int
    var email: String?
    var name: String?
    var profileImageURL: String?
    var bio: String?
    var postCount: Int?
    var website: String?
    var followingCount: Int?
    var followersCount: Int?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case profileImageURL = "profile_image_url"
        case bio
        case postCount = "post_count"
        case website
        case followingCount = "following_count"
        case followersCount = "followers_count"
        case createdAt = "created_at"
    }
}


/// Laravel の POST /api/users に送信するユーザー作成リクエスト
struct CreateUserRequest: Codable {
    var id: Int
    var email: String?
}

extension CreateUserRequest {
    init(from user: User) {
        self.id = user.id
        self.email = user.email
    }
}

struct UserResponse: Codable {
    let data: User
}
