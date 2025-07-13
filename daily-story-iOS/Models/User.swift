import Foundation

struct User: Codable, Identifiable {
    var id: Int
    var email: String?
    var name: String?
    var profileImageURL: String?
    var profileIconImageURL: String?
    var bio: String?
    var city: String?
    var birthday: String?
    var postCount: Int?
    var website: String?
    var followingCount: Int?
    var followersCount: Int?
    var hasCompletedSetup: Bool?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case profileImageURL = "profile_image_url"
        case profileIconImageURL = "profile_icon_image_url"
        case bio
        case city
        case birthday
        case postCount = "post_count"
        case website
        case followingCount = "following_count"
        case followersCount = "followers_count"
        case hasCompletedSetup = "has_completed_setup"
        case createdAt = "created_at"
    }
}

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
