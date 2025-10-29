import Foundation

protocol FetchShopsUseCase { func execute(genre: ShopGenre?, latitude: Double?, longitude: Double?, radius: Double?) async throws -> [Shop] }
protocol FetchShopPostsUseCase { func execute(shopId: Int) async throws -> [Post] }

final class FetchShopsUseCaseImpl: FetchShopsUseCase {
    private let repository: ShopRepository
    init(repository: ShopRepository) { self.repository = repository }
    func execute(genre: ShopGenre?, latitude: Double?, longitude: Double?, radius: Double?) async throws -> [Shop] {
        try await repository.fetchShops(genre: genre, latitude: latitude, longitude: longitude, radius: radius)
    }
}

final class FetchShopPostsUseCaseImpl: FetchShopPostsUseCase {
    private let repository: ShopRepository
    init(repository: ShopRepository) { self.repository = repository }
    func execute(shopId: Int) async throws -> [Post] { try await repository.fetchShopPosts(shopId: shopId) }
}

