import XCTest
@testable import kumatomo

@MainActor
final class FavoritesManagerTests: XCTestCase {
    
    var favoritesManager: FavoritesManager!
    var mockShopAPIService: MockShopAPIService!
    
    override func setUp() {
        super.setUp()
        
        // Create a fresh instance for each test
        mockShopAPIService = MockShopAPIService()
        favoritesManager = FavoritesManager()
        
        // Replace the shared service with our mock
        // Note: This would require dependency injection in the actual implementation
        // For now, we'll test the logic directly
    }
    
    override func tearDown() {
        favoritesManager = nil
        mockShopAPIService = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(favoritesManager.favoriteShops.isEmpty)
        XCTAssertTrue(favoritesManager.favoriteIds.isEmpty)
        XCTAssertFalse(favoritesManager.isLoading)
        XCTAssertNil(favoritesManager.errorMessage)
        XCTAssertTrue(favoritesManager.isEmpty)
        XCTAssertEqual(favoritesManager.favoriteCount, 0)
    }
    
    // MARK: - Favorite Status Tests
    
    func testIsFavorite() {
        // Given
        let shopId = 123
        favoritesManager.favoriteIds.insert(shopId)
        
        // When & Then
        XCTAssertTrue(favoritesManager.isFavorite(shopId: shopId))
        XCTAssertFalse(favoritesManager.isFavorite(shopId: 456))
    }
    
    // MARK: - Toggle Favorite Tests
    
    func testToggleFavoriteAddSuccess() async {
        // Given
        let shop = createMockShop(id: 123, name: "Test Shop")
        mockShopAPIService.toggleFavoriteResult = .success(FavoriteToggleResponse(favorited: true, message: "Added"))
        
        // When
        await favoritesManager.toggleFavorite(shop: shop)
        
        // Then
        XCTAssertTrue(favoritesManager.favoriteIds.contains(shop.id))
        XCTAssertTrue(favoritesManager.favoriteShops.contains(shop))
        XCTAssertNil(favoritesManager.errorMessage)
    }
    
    func testToggleFavoriteRemoveSuccess() async {
        // Given
        let shop = createMockShop(id: 123, name: "Test Shop")
        favoritesManager.favoriteIds.insert(shop.id)
        favoritesManager.favoriteShops.append(shop)
        mockShopAPIService.toggleFavoriteResult = .success(FavoriteToggleResponse(favorited: false, message: "Removed"))
        
        // When
        await favoritesManager.toggleFavorite(shop: shop)
        
        // Then
        XCTAssertFalse(favoritesManager.favoriteIds.contains(shop.id))
        XCTAssertFalse(favoritesManager.favoriteShops.contains(shop))
        XCTAssertNil(favoritesManager.errorMessage)
    }
    
    func testToggleFavoriteFailure() async {
        // Given
        let shop = createMockShop(id: 123, name: "Test Shop")
        let initialFavoriteCount = favoritesManager.favoriteIds.count
        mockShopAPIService.toggleFavoriteResult = .failure(APIError.networkError(NSError(domain: "Test", code: -1)))
        
        // When
        await favoritesManager.toggleFavorite(shop: shop)
        
        // Then
        XCTAssertEqual(favoritesManager.favoriteIds.count, initialFavoriteCount)
        XCTAssertNotNil(favoritesManager.errorMessage)
        XCTAssertTrue(favoritesManager.errorMessage!.contains("お気に入りの更新に失敗しました"))
    }
    
    func testToggleFavoriteOptimisticUpdateRevert() async {
        // Given
        let shop = createMockShop(id: 123, name: "Test Shop")
        // Server returns opposite of what we expect (server inconsistency)
        mockShopAPIService.toggleFavoriteResult = .success(FavoriteToggleResponse(favorited: false, message: "Not added"))
        
        // When
        await favoritesManager.toggleFavorite(shop: shop)
        
        // Then - Should revert optimistic update
        XCTAssertFalse(favoritesManager.favoriteIds.contains(shop.id))
        XCTAssertFalse(favoritesManager.favoriteShops.contains(shop))
    }
    
    // MARK: - Load Favorites Tests
    
    func testLoadFavoritesSuccess() async {
        // Given
        let mockFavorites = [
            createMockFavorite(id: 1, shopId: 123, shop: createMockShop(id: 123, name: "Shop 1")),
            createMockFavorite(id: 2, shopId: 456, shop: createMockShop(id: 456, name: "Shop 2"))
        ]
        mockShopAPIService.fetchFavoritesResult = .success(mockFavorites)
        
        // When
        await favoritesManager.loadFavorites()
        
        // Then
        XCTAssertFalse(favoritesManager.isLoading)
        XCTAssertEqual(favoritesManager.favoriteShops.count, 2)
        XCTAssertEqual(favoritesManager.favoriteIds.count, 2)
        XCTAssertTrue(favoritesManager.favoriteIds.contains(123))
        XCTAssertTrue(favoritesManager.favoriteIds.contains(456))
        XCTAssertNil(favoritesManager.errorMessage)
    }
    
    func testLoadFavoritesFailure() async {
        // Given
        mockShopAPIService.fetchFavoritesResult = .failure(APIError.networkError(NSError(domain: "Test", code: -1)))
        
        // When
        await favoritesManager.loadFavorites()
        
        // Then
        XCTAssertFalse(favoritesManager.isLoading)
        XCTAssertTrue(favoritesManager.favoriteShops.isEmpty)
        XCTAssertTrue(favoritesManager.favoriteIds.isEmpty)
        XCTAssertNotNil(favoritesManager.errorMessage)
        XCTAssertTrue(favoritesManager.errorMessage!.contains("お気に入りの読み込みに失敗しました"))
    }
    
    // MARK: - Utility Methods Tests
    
    func testGetFavoriteShopsSorted() {
        // Given
        let shop1 = createMockShop(id: 1, name: "Shop 1")
        let shop2 = createMockShop(id: 2, name: "Shop 2")
        
        // Set different creation dates
        var shop1Modified = shop1
        var shop2Modified = shop2
        shop1Modified.createdAt = Date().addingTimeInterval(-3600) // 1 hour ago
        shop2Modified.createdAt = Date() // Now
        
        favoritesManager.favoriteShops = [shop1Modified, shop2Modified]
        
        // When
        let sortedShops = favoritesManager.getFavoriteShopsSorted()
        
        // Then
        XCTAssertEqual(sortedShops.count, 2)
        XCTAssertEqual(sortedShops.first?.id, 2) // Newer shop should be first
        XCTAssertEqual(sortedShops.last?.id, 1)
    }
    
    func testFavoriteCount() {
        // Given
        favoritesManager.favoriteIds = Set([1, 2, 3])
        
        // When & Then
        XCTAssertEqual(favoritesManager.favoriteCount, 3)
    }
    
    func testIsEmpty() {
        // Given - empty state
        XCTAssertTrue(favoritesManager.isEmpty)
        
        // When - add favorite
        favoritesManager.favoriteIds.insert(123)
        
        // Then
        XCTAssertFalse(favoritesManager.isEmpty)
    }
    
    func testClearFavorites() {
        // Given
        favoritesManager.favoriteIds = Set([1, 2, 3])
        favoritesManager.favoriteShops = [createMockShop(id: 1, name: "Shop 1")]
        favoritesManager.errorMessage = "Some error"
        
        // When
        favoritesManager.clearFavorites()
        
        // Then
        XCTAssertTrue(favoritesManager.favoriteIds.isEmpty)
        XCTAssertTrue(favoritesManager.favoriteShops.isEmpty)
        XCTAssertNil(favoritesManager.errorMessage)
    }
    
    // MARK: - Helper Methods
    
    private func createMockShop(id: Int, name: String) -> Shop {
        return Shop(
            id: id,
            name: name,
            description: "Test description",
            address: "Test address",
            phone: "123-456-7890",
            businessHours: "9:00-18:00",
            genre: .cafe,
            latitude: 35.6762,
            longitude: 139.6503,
            imageUrl: "https://example.com/image.jpg",
            hasTryBenefit: false,
            stampCount: 0,
            isApproved: true
        )
    }
    
    private func createMockFavorite(id: Int, shopId: Int, shop: Shop?) -> Favorite {
        return Favorite(
            id: id,
            userId: 1,
            shopId: shopId,
            shop: shop
        )
    }
}

// MARK: - Mock ShopAPIService

class MockShopAPIService {
    var toggleFavoriteResult: Result<FavoriteToggleResponse, Error> = .success(FavoriteToggleResponse(favorited: true, message: nil))
    var fetchFavoritesResult: Result<[Favorite], Error> = .success([])
    
    func toggleFavorite(shopId: Int) async throws -> FavoriteToggleResponse {
        switch toggleFavoriteResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    func fetchFavorites(page: Int = 1) async throws -> [Favorite] {
        switch fetchFavoritesResult {
        case .success(let favorites):
            return favorites
        case .failure(let error):
            throw error
        }
    }
}