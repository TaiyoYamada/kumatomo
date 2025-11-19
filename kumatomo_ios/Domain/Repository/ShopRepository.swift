import Foundation

protocol ShopRepository {
    func fetchShops(genre: ShopGenre?, latitude: Double?, longitude: Double?, radius: Double?) async throws -> [Shop]
    func fetchShopPosts(shopId: Int) async throws -> [Post]
}
