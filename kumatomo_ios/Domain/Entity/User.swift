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

    func validateEmail() -> ValidationResult {
        guard let email else {
            return .invalid(message: "メールアドレスが設定されていません")
        }
        return ProfileFormValidation.validateEmail(email)
    }

    func validateName() -> ValidationResult {
        guard let name else {
            return .invalid(message: "名前が設定されていません")
        }
        return ProfileFormValidation.validateName(name)
    }

    func validateUsername() -> ValidationResult {
        guard let username else {
            return .invalid(message: "ユーザーネームが設定されていません")
        }
        return ProfileFormValidation.validateUsername(username)
    }

    func validateBio() -> ValidationResult {
        return ProfileFormValidation.validateBio(bio ?? "")
    }

    func validateLocation() -> ValidationResult {
        return ProfileFormValidation.validateLocation(location ?? "")
    }

    func validateBirthday() -> ValidationResult {
        var birthdayDate: Date?
        if let birthdayString = birthday {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthdayDate = formatter.date(from: birthdayString)
        }
        return ProfileFormValidation.validateBirthday(birthdayDate)
    }

    func validateProfile() -> [String] {
        return ProfileFormValidation.validateCompleteProfile(
            name: name ?? "",
            username: username ?? "",
            email: email ?? "",
            bio: bio ?? "",
            location: location ?? "",
            birthday: nil
        )
    }

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
