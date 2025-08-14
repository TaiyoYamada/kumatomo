import Foundation

struct PostImage: Identifiable, Codable {
    var id: Int
    var postId: Int?
    var imageUrl: String
    var displayOrder: Int?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case imageUrl = "image_url"
        case imageUrlAlt = "imageUrl"  // camelCase版
        case url = "url"               // シンプル版
        case displayOrder = "display_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // デバッグ用のinit
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 利用可能なキーをログ出力
        let availableKeys = container.allKeys.map { $0.stringValue }
        print("🔍 PostImage利用可能キー: \(availableKeys)")
        
        id = try container.decode(Int.self, forKey: .id)
        postId = try container.decodeIfPresent(Int.self, forKey: .postId)
        
        // 複数のキーを試してimageUrlを取得
        if let url = try? container.decode(String.self, forKey: .imageUrl) {
            imageUrl = url
            print("🔍 image_urlキーを使用: \(imageUrl)")
        } else if let url = try? container.decode(String.self, forKey: .imageUrlAlt) {
            imageUrl = url
            print("🔍 imageUrlキーを使用")
        } else if let url = try? container.decode(String.self, forKey: .url) {
            imageUrl = url
            print("🔍 urlキーを使用")
        } else {
            print("🚨 画像URLキーが見つかりません。利用可能キー: \(availableKeys)")
            throw DecodingError.keyNotFound(CodingKeys.imageUrl, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "image_url, imageUrl, url のいずれのキーも見つかりません"))
        }
        
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 1
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        
        print("🔍 PostImage デコード結果: id=\(id), postId=\(postId ?? -1), imageUrl=\(imageUrl)")
    }
    
    // Encodable実装
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(postId, forKey: .postId)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(displayOrder, forKey: .displayOrder)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

extension PostImage {
    init(id: Int = 0, postId: Int, imageUrl: String, displayOrder: Int = 1) {
        self.id = id
        self.postId = postId
        self.imageUrl = imageUrl
        self.displayOrder = displayOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}