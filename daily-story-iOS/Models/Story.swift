import Foundation

struct Story: Identifiable, Codable {
    var id: Int
    var userId: Int?
    var title: String?
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
        case title
        case content
        case imageUrl = "image_url"
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
}

// POST /api/stories に送信するストーリー作成リクエスト
extension Story {
    init(id: Int = 0, userId: Int, title: String? = nil, content: String, imageUrl: String? = nil, tags: [String]? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.imageUrl = imageUrl
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
    }
}
