import Foundation

// MARK: - Profile Request Models

struct CreateProfileRequest: Codable {
    let name: String
    let email: String
    let username: String
    let bio: String?
    let location: String?
    let birthday: String?
    
    enum CodingKeys: String, CodingKey {
        case name, email, username, bio, location, birthday
    }
}

struct UpdateProfileRequest: Codable {
    let name: String?
    let email: String?
    let username: String?
    let bio: String?
    let location: String?
    let birthday: String?
    let profileImageURL: String?
    let coverImageURL: String?
    
    // Use default camelCase keys to align with API
}

struct ProfileValidationResponse: Codable {
    let isValid: Bool
    let errors: [String: [String]]
    let warnings: [String]?
    
    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case errors, warnings
    }
}

// MARK: - User Extensions for Request Creation

extension User {
    func toCreateRequest() -> CreateProfileRequest {
        return CreateProfileRequest(
            name: name ?? "",
            email: email ?? "",
            username: username ?? "",
            bio: bio,
            location: location,
            birthday: birthday,
        )
    }
    
    func toUpdateRequest() -> UpdateProfileRequest {
        return UpdateProfileRequest(
            name: name,
            email: email,
            username: username,
            bio: bio,
            location: location,
            birthday: birthday,
            profileImageURL: profileImageURL,
            coverImageURL: coverImageURL
        )
    }
    
    func canBeDeleted() -> Bool {
        // Add business logic for determining if a profile can be deleted
        // For now, assume all profiles can be deleted
        return true
    }
}
