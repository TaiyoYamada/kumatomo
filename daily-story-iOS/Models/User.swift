import Foundation

/// ユーザーモデル（SwiftUI / Laravel API 両対応）
struct User: Codable, Identifiable {
    var id: Int?
    var email: String
    var name: String
    var profileImageURL: String?
    var bio: String
    var website: String?
    var followingCount: Int
    var followersCount: Int
    var partnerId: String?
    var pairId: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case profileImageURL = "profile_image_url"
        case bio
        case website
        case followingCount = "following_count"
        case followersCount = "followers_count"
        case partnerId = "partner_id"
        case pairId = "pair_id"
        case createdAt = "created_at"
    }
}


/// Laravel の POST /api/users に送信するユーザー作成リクエスト
struct CreateUserRequest: Codable {
    var id: Int?
    var email: String
    var name: String
    var birthDate: Date?
    var profileImageURL: String?
    var partnerId: String?
    var pairId: String?
    var bio: String
}

extension CreateUserRequest {
    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.name = user.name
        self.profileImageURL = user.profileImageURL
        self.partnerId = user.partnerId
        self.pairId = user.pairId
        self.bio = user.bio
    }
}

struct UserResponse: Codable {
    let data: User
}
