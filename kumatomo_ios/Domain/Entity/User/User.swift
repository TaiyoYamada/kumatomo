import Foundation

// MARK: - User

struct User: Codable, Identifiable, Equatable {
    var id: Int
    var email: String?
    var name: String?
    var username: String?
    var profileImageURL: String?
    var coverImageURL: String?
    var bio: String?
    var location: String?
    var birthday: String?
    var postCount: Int?
    var followingCount: Int?
    var followersCount: Int?
    var hasCompletedSetup: Bool?
    var createdAt: Date?
    var isVerified: Bool?
    var joinedDate: String?

}

extension User {

    var isProfileComplete: Bool {
        guard let email, !email.isEmpty,
              let name, !name.isEmpty,
              let username, !username.isEmpty else { return false }
        return true
    }

    func updatedProfile(
        email: String? = nil,
        name: String? = nil,
        username: String? = nil,
        bio: String? = nil,
        location: String? = nil,
        birthday: String? = nil,
        profileImageURL: String? = nil,
        coverImageURL: String? = nil
    ) -> User {
        var updatedUser = self

        if let email { updatedUser.email = email }
        if let name { updatedUser.name = name }
        if let username { updatedUser.username = username }
        if let bio { updatedUser.bio = bio }
        if let location { updatedUser.location = location }
        if let birthday { updatedUser.birthday = birthday }
        if let profileImageURL { updatedUser.profileImageURL = profileImageURL }
        if let coverImageURL { updatedUser.coverImageURL = coverImageURL }

        return updatedUser
    }
}

// MARK: - CreateUserRequest

struct CreateUserRequest: Codable {
    var id: Int
    var email: String?
}

extension CreateUserRequest {
    init(from user: User) {
        id = user.id
        email = user.email
    }
}
