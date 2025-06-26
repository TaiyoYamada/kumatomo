import Foundation

struct Story: Identifiable, Codable {
    var id: Int
    var userId: Int
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    // 関連するユーザー情報
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case content
        case createdAt
        case updatedAt
        case user
    }
}
// Laravel の POST /api/stories に送信するストーリー作成リクエスト
extension Story {
    init(id: Int = 0, userId: Int, content: String) {
        self.id = id
        self.userId = userId
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
    }
}
