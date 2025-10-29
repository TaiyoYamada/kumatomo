import Foundation

struct Favorite: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    let shopId: Int
    let shop: Shop?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case shopId = "shop_id"
        case shop
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Favorite {
    init(id: Int = 0, userId: Int, shopId: Int, shop: Shop? = nil) {
        self.id = id
        self.userId = userId
        self.shopId = shopId
        self.shop = shop
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}