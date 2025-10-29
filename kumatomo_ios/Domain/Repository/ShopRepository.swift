import Foundation

// Domain layer protocol for shop-related operations
protocol ShopRepository {
    func fetchShops(genre: ShopGenre?, latitude: Double?, longitude: Double?, radius: Double?) async throws -> [Shop]
    func fetchShopPosts(shopId: Int) async throws -> [Post]
}
