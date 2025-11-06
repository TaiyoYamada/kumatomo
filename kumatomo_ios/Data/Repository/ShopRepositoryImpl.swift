import Foundation

final class ShopRepositoryImpl: ShopRepository {
    private let service: ShopAPIService

    init(service: ShopAPIService = .shared) {
        self.service = service
    }

    func fetchShops(genre: ShopGenre?, latitude: Double?, longitude: Double?, radius: Double?) async throws -> [Shop] {
        let genreString: String? = genre?.rawValue
        let radiusInt: Int? = radius.map { Int($0) }
        return try await service.fetchShops(genre: genreString, latitude: latitude, longitude: longitude, radius: radiusInt)
    }

    func fetchShopPosts(shopId: Int) async throws -> [Post] {
        try await service.fetchShopPosts(shopId: shopId)
    }
}
