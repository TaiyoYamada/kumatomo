import Foundation

struct Post: Identifiable, Codable {
    var id: Int
    var userId: Int?
    var shopId: Int?
    var content: String
    var imageUrl: String?
    var tags: [String]?
    var createdAt: Date?
    var updatedAt: Date?
    
    // 関連データ
    var user: User?
    var shop: Shop?
    var images: [PostImage]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case shopId = "shop_id"
        case content
        case imageUrl = "image_url"
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case shop
        case images
    }
    
    // デバッグ用のinit
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 利用可能なキーをログ出力
        print("🔍 Post利用可能キー: \(container.allKeys.map { $0.stringValue })")
        
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decodeIfPresent(Int.self, forKey: .userId)
        shopId = try container.decodeIfPresent(Int.self, forKey: .shopId)
        content = try container.decode(String.self, forKey: .content)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        user = try container.decodeIfPresent(User.self, forKey: .user)
        shop = try container.decodeIfPresent(Shop.self, forKey: .shop)
        images = try container.decodeIfPresent([PostImage].self, forKey: .images)
        
        print("🔍 Post デコード結果: id=\(id), images=\(images?.count ?? 0)枚")
    }
    
    // Encodable実装
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(shopId, forKey: .shopId)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(shop, forKey: .shop)
        try container.encodeIfPresent(images, forKey: .images)
    }
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
