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

    // The CodingKeys enum has been removed to allow the JSONDecoder's
    // .convertFromSnakeCase strategy to handle the mapping automatically.
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
