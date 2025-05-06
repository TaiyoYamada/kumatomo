import Foundation

/// ユーザーモデル（SwiftUI / Laravel API 両対応）
struct User: Codable, Identifiable {
    var id: Int?
    var email: String
    var name: String
    var birthDate: Date?
    var profileImageURL: String?
    var createdAt: Date?
    var partnerId: String?
    var pairId: String?
    var relationshipStartDate: Date?
    var bio: String
    var interests: [String]
    var relationshipStatus: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case birthDate = "birth_date"
        case profileImageURL = "profile_image_url"
        case createdAt = "created_at"
        case partnerId = "partner_id"
        case pairId = "pair_id"
        case relationshipStartDate = "relationship_start_date"
        case bio
        case interests
        case relationshipStatus = "relationship_status"
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
    var relationshipStartDate: Date?
    
    var bio: String
    var interests: [String]
    var relationshipStatus: String
}

extension CreateUserRequest {
    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.name = user.name
        self.birthDate = user.birthDate
        self.profileImageURL = user.profileImageURL
        self.partnerId = user.partnerId
        self.pairId = user.pairId
        self.relationshipStartDate = user.relationshipStartDate
        self.bio = user.bio
        self.interests = user.interests
        self.relationshipStatus = user.relationshipStatus
    }
}

struct UserResponse: Codable {
    let data: User
}
