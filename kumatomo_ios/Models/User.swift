import Foundation

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

    // The CodingKeys enum has been removed to allow the JSONDecoder's
    // .convertFromSnakeCase strategy to handle the mapping automatically.
}

// MARK: - User Profile Validation Extension
extension User {
    
    func validateEmail() -> ValidationResult {
        guard let email = self.email else {
            return .invalid(message: "メールアドレスが設定されていません")
        }
        return ProfileFormValidation.validateEmail(email)
    }
    
    func validateName() -> ValidationResult {
        guard let name = self.name else {
            return .invalid(message: "名前が設定されていません")
        }
        return ProfileFormValidation.validateName(name)
    }
    
    /// Validates the user's username field
    func validateUsername() -> ValidationResult {
        guard let username = self.username else {
            return .invalid(message: "ユーザーネームが設定されていません")
        }
        return ProfileFormValidation.validateUsername(username)
    }
    
    /// Validates the user's bio field
    func validateBio() -> ValidationResult {
        return ProfileFormValidation.validateBio(bio ?? "")
    }
    
    /// Validates the user's location field
    func validateLocation() -> ValidationResult {
        return ProfileFormValidation.validateLocation(location ?? "")
    }
    
    /// Validates the user's birthday field
    func validateBirthday() -> ValidationResult {
        // Convert birthday string to Date if needed
        var birthdayDate: Date?
        if let birthdayString = birthday {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthdayDate = formatter.date(from: birthdayString)
        }
        return ProfileFormValidation.validateBirthday(birthdayDate)
    }
    
    /// Validates all profile fields and returns a list of validation errors
    func validateProfile() -> [String] {
        return ProfileFormValidation.validateCompleteProfile(
            name: name ?? "",
            username: username ?? "",
            email: email ?? "",
            bio: bio ?? "",
            location: location ?? "",
            birthday: nil // Convert birthday string to Date if needed
        )
    }
    
    
    var isProfileComplete: Bool {
        return email != nil && !email!.isEmpty &&
               name != nil && !name!.isEmpty &&
               username != nil && !username!.isEmpty
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
        
        if let email = email { updatedUser.email = email }
        if let name = name { updatedUser.name = name }
        if let username = username { updatedUser.username = username }
        if let bio = bio { updatedUser.bio = bio }
        if let location = location { updatedUser.location = location }
        if let birthday = birthday { updatedUser.birthday = birthday }
        if let profileImageURL = profileImageURL { updatedUser.profileImageURL = profileImageURL }
        if let coverImageURL = coverImageURL { updatedUser.coverImageURL = coverImageURL }
        
        return updatedUser
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
