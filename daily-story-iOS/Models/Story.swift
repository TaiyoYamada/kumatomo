import Foundation

struct Story: Identifiable, Codable {
    var id: Int?
    var userId: Int
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    // 関連するユーザー情報
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
    
    /// 新規作成用のイニシャライザ
    init(userId: Int, content: String) {
        self.id = nil
        self.userId = userId
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
    }
}

// モックデータ用拡張
extension Story {
    static let mockStories = [
        Story(userId: 1, content: "今日は素晴らしい一日でした。富士山を見に行って、美しい景色に感動しました。自然の力を感じる旅でした。"),
        Story(userId: 2, content: "新しいカフェで美味しいコーヒーを飲みました。静かな空間で読書するのは至福の時間です。"),
        Story(userId: 3, content: "プログラミングの課題がやっと完成！思ったより時間がかかったけど、達成感があります。"),
        Story(userId: 1, content: "友達と久しぶりに会って話したら、あっという間に時間が過ぎていました。人との繋がりって大切だな。"),
        Story(userId: 4, content: "今日から新しい習慣としてジョギングを始めました。健康的な生活を目指します！")
    ]
}