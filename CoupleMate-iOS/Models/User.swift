import Foundation

/// ユーザーモデル（SwiftUI / Laravel API 両対応）
struct User: Codable, Identifiable {
    var id: Int?                    // ユーザーID
    var email: String                 // メールアドレス
    var name: String              // 氏名
    var birthDate: Date?              // 生年月日（任意）
    var profileImageURL: String?      // プロフィール画像 URL（任意）
    var createdAt: Date?              // 作成日（Laravel から返される）
    var partnerId: String?            // パートナーのユーザーID（任意）
    var pairId: String?               // カップルの共有ID（任意）
    var relationshipStartDate: Date?  // 記念日（任意）
    var bio: String                   // 自己紹介
    var interests: [String]           // 興味・関心
    var relationshipStatus: String    // 恋愛ステータス（Single, In a relationship 等）
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
