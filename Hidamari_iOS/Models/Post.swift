import Foundation

struct Post: Identifiable, Codable {
    var id: Int
    var userId: Int?
    var shopId: Int?
    var content: String
    var imageUrl: String? // Deprecated: use images array instead
    var tags: [String]?
    var createdAt: Date?
    var updatedAt: Date?
    
    // 関連データ
    var user: User?
    var shop: Shop?
    var images: [PostImage]?
}

extension Post {
    init(id: Int = 0, userId: Int, content: String, shopId: Int? = nil, imageUrl: String? = nil, tags: [String]? = nil) {
        self.id = id
        self.userId = userId
        self.shopId = shopId
        self.content = content
        self.imageUrl = imageUrl
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
        self.shop = nil
        self.images = nil
    }
    
    // Mutable version for optimistic updates
    mutating func updateContent(_ newContent: String) {
        self.content = newContent
        self.updatedAt = Date()
    }
    
    mutating func updateShop(_ newShop: Shop?) {
        self.shop = newShop
        self.shopId = newShop?.id
        self.updatedAt = Date()
    }
    
    mutating func updateTags(_ newTags: [String]?) {
        self.tags = newTags
        self.updatedAt = Date()
    }
}
