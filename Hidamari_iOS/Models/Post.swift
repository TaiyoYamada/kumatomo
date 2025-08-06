import Foundation

struct Post: Identifiable, Codable {
    var id: Int
    var userId: Int?
    var content: String
    var imageUrl: String?
    var tags: [String]?
    var createdAt: Date?
    var updatedAt: Date?
    
    // 関連するユーザー情報
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case imageUrl = "image_url"
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
}

extension Post {
    init(id: Int = 0, userId: Int, content: String, imageUrl: String? = nil, tags: [String]? = nil) {
        self.id = id
        self.userId = userId
        self.content = content
        self.imageUrl = imageUrl
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
    }
}
