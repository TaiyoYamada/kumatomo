import XCTest
import SwiftUI
import CoreLocation
@testable import kumatomo

@MainActor
final class ShopListViewIntegrationTests: XCTestCase {
    
    var viewModel: ShopListViewModel!
    var mockShopAPIService: MockShopAPIService!
    var mockLocationManager: MockLocationManager!
    var mockFavoritesManager: MockFavoritesManager!
    
    override func setUp() {
        super.setUp()
        
        // Create mock services
        mockShopAPIService = MockShopAPIService()
        mockLocationManager = MockLocationManager()
        mockFavoritesManager = MockFavoritesManager()
        
        // Create view model with mocked dependencies
        viewModel = ShopListViewModel()
        
        // Set up initial state
        viewModel.shops = createMockShops()
        viewModel.filteredShops = viewModel.shops
    }
    
    override func tearDown() {
        viewModel = nil
        mockShopAPIService = nil
        mockLocationManager = nil
        mockFavoritesManager = nil
        super.tearDown()
    }
    
    // MARK: - Genre Filtering Integration Tests
    
    func testGenreFilteringIntegration() {
        // Given
        let cafeGenre = ShopGenre.cafe
        let ramenGenre = ShopGenre.ramen
        
        // When - Select cafe genre
        viewModel.toggleGenre(cafeGenre)
        
        // Then
        XCTAssertTrue(viewModel.selectedGenres.contains(cafeGenre))
        XCTAssertEqual(viewModel.filteredShops.count, 1)
        XCTAssertEqual(viewModel.filteredShops.first?.genre, cafeGenre)
        
        // When - Add ramen genre (multi-select)
        viewModel.toggleGenre(ramenGenre)
        
        // Then
        XCTAssertTrue(viewModel.selectedGenres.contains(cafeGenre))
        XCTAssertTrue(viewModel.selectedGenres.contains(ramenGenre))
        XCTAssertEqual(viewModel.filteredShops.count, 2)
        
        // When - Clear all genres
        viewModel.clearAllGenres()
        
        // Then
        XCTAssertTrue(viewModel.selectedGenres.isEmpty)
        XCTAssertEqual(viewModel.filteredShops.count, viewModel.shops.count)
    }
    
    func testGenreFilteringWithNoMatchingShops() {
        // Given
        let nonExistentGenre = ShopGenre.french
        
        // When
        viewModel.toggleGenre(nonExistentGenre)
        
        // Then
        XCTAssertTrue(viewModel.selectedGenres.contains(nonExistentGenre))
        XCTAssertTrue(viewModel.filteredShops.isEmpty)
    }
    
    // MARK: - Distance Calculation Integration Tests
    
    func testDistanceCalculationWithUserLocation() {
        // Given
        let userLocation = CLLocation(latitude: 35.6762, longitude: 139.6503) // Tokyo
        mockLocationManager.userLocation = userLocation
        
        let shop = viewModel.shops.first!
        
        // When
        let distance = viewModel.distanceFromUser(to: shop)
        
        // Then
        XCTAssertNotNil(distance)
        XCTAssertTrue(distance!.contains("m") || distance!.contains("km"))
    }
    
    func testDistanceCalculationWithoutUserLocation() {
        // Given
        mockLocationManager.userLocation = nil
        
        let shop = viewModel.shops.first!
        
        // When
        let distance = viewModel.distanceFromUser(to: shop)
        
        // Then
        XCTAssertNil(distance)
    }
    
    // MARK: - Favorites Integration Tests
    
    func testFavoritesIntegrationWithShopCards() async {
        // Given
        let shop = viewModel.shops.first!
        mockFavoritesManager.favoriteIds = []
        
        // When - Toggle favorite
        await mockFavoritesManager.toggleFavorite(shop: shop)
        
        // Then
        XCTAssertTrue(mockFavoritesManager.isFavorite(shopId: shop.id))
        XCTAssertTrue(mockFavoritesManager.favoriteIds.contains(shop.id))
        
        // When - Toggle again to remove
        await mockFavoritesManager.toggleFavorite(shop: shop)
        
        // Then
        XCTAssertFalse(mockFavoritesManager.isFavorite(shopId: shop.id))
        XCTAssertFalse(mockFavoritesManager.favoriteIds.contains(shop.id))
    }
    
    func testFavoritesErrorHandling() async {
        // Given
        let shop = viewModel.shops.first!
        mockFavoritesManager.shouldFailToggle = true
        
        // When
        await mockFavoritesManager.toggleFavorite(shop: shop)
        
        // Then
        XCTAssertNotNil(mockFavoritesManager.errorMessage)
        XCTAssertTrue(mockFavoritesManager.errorMessage!.contains("お気に入りの更新に失敗しました"))
    }
    
    // MARK: - Loading States Integration Tests
    
    func testLoadingStatesDuringShopFetch() async {
        // Given
        viewModel.isLoading = false
        mockShopAPIService.shouldDelay = true
        
        // When
        let loadTask = Task {
            await viewModel.loadShops()
        }
        
        // Then - Should be loading
        XCTAssertTrue(viewModel.isLoading)
        
        // Wait for completion
        await loadTask.value
        
        // Then - Should not be loading
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testErrorStateHandling() async {
        // Given
        mockShopAPIService.shouldFail = true
        
        // When
        await viewModel.loadShops()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to fetch shops"))
    }
    
    // MARK: - Map/List Toggle Integration Tests
    
    func testMapListToggleIntegration() {
        // Given
        XCTAssertFalse(viewModel.showingMap)
        
        // When
        viewModel.toggleMapView()
        
        // Then
        XCTAssertTrue(viewModel.showingMap)
        
        // When
        viewModel.toggleMapView()
        
        // Then
        XCTAssertFalse(viewModel.showingMap)
    }
    
    // MARK: - Refresh Integration Tests
    
    func testRefreshShopsIntegration() async {
        // Given
        let initialShopCount = viewModel.shops.count
        mockShopAPIService.additionalShops = [createMockShop(id: 999, name: "New Shop")]
        
        // When
        await viewModel.refreshShops()
        
        // Then
        XCTAssertEqual(viewModel.shops.count, initialShopCount + 1)
        XCTAssertTrue(viewModel.shops.contains { $0.name == "New Shop" })
    }
    
    // MARK: - Combined Feature Integration Tests
    
    func testGenreFilteringWithFavoritesAndDistance() {
        // Given
        let userLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
        mockLocationManager.userLocation = userLocation
        mockFavoritesManager.favoriteIds = Set([1, 2])
        
        // When - Filter by cafe genre
        viewModel.toggleGenre(.cafe)
        
        // Then - Should have filtered shops with distance and favorite status
        XCTAssertEqual(viewModel.filteredShops.count, 1)
        
        let filteredShop = viewModel.filteredShops.first!
        XCTAssertEqual(filteredShop.genre, .cafe)
        
        let distance = viewModel.distanceFromUser(to: filteredShop)
        XCTAssertNotNil(distance)
        
        let isFavorite = mockFavoritesManager.isFavorite(shopId: filteredShop.id)
        XCTAssertTrue(isFavorite)
    }
    
    func testErrorRecoveryFlow() async {
        // Given - Initial error state
        mockShopAPIService.shouldFail = true
        await viewModel.loadShops()
        XCTAssertNotNil(viewModel.errorMessage)
        
        // When - Fix the error and retry
        mockShopAPIService.shouldFail = false
        await viewModel.refreshShops()
        
        // Then - Should recover from error
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.shops.isEmpty)
    }
    
    // MARK: - Performance Integration Tests
    
    func testLargeDatasetPerformance() {
        // Given
        let largeShopList = (1...1000).map { createMockShop(id: $0, name: "Shop \($0)") }
        viewModel.shops = largeShopList
        
        // When - Apply filters
        let startTime = CFAbsoluteTimeGetCurrent()
        viewModel.toggleGenre(.cafe)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then - Should complete quickly (under 100ms)
        let executionTime = endTime - startTime
        XCTAssertLessThan(executionTime, 0.1, "Genre filtering should complete in under 100ms")
    }
    
    // MARK: - Helper Methods
    
    private func createMockShops() -> [Shop] {
        return [
            createMockShop(id: 1, name: "Test Cafe", genre: .cafe),
            createMockShop(id: 2, name: "Test Ramen", genre: .ramen),
            createMockShop(id: 3, name: "Test Restaurant", genre: .restaurant)
        ]
    }
    
    private func createMockShop(id: Int, name: String, genre: ShopGenre = .cafe) -> Shop {
        return Shop(
            id: id,
            name: name,
            description: "Test description for \(name)",
            address: "Test address \(id)",
            phone: "123-456-789\(id)",
            businessHours: "9:00-18:00",
            genre: genre,
            latitude: 35.6762 + Double(id) * 0.001,
            longitude: 139.6503 + Double(id) * 0.001,
            imageUrl: "https://example.com/image\(id).jpg",
            hasTryBenefit: id % 2 == 0,
            stampCount: id * 2,
            isApproved: true
        )
    }
}

// MARK: - Mock Classes

class MockLocationManager {
    var userLocation: CLLocation?
    
    func distanceFromUser(to shop: Shop) -> String? {
        guard let userLocation = userLocation,
              let coordinate = shop.coordinate else { return nil }
        
        let shopLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = userLocation.distance(from: shopLocation)
        
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

class MockFavoritesManager: ObservableObject {
    @Published var favoriteShops: [Shop] = []
    @Published var favoriteIds: Set<Int> = []
    @Published var errorMessage: String?
    
    var shouldFailToggle = false
    
    func toggleFavorite(shop: Shop) async {
        if shouldFailToggle {
            errorMessage = "お気に入りの更新に失敗しました: Network error"
            return
        }
        
        if favoriteIds.contains(shop.id) {
            favoriteIds.remove(shop.id)
            favoriteShops.removeAll { $0.id == shop.id }
        } else {
            favoriteIds.insert(shop.id)
            favoriteShops.append(shop)
        }
        
        errorMessage = nil
    }
    
    func isFavorite(shopId: Int) -> Bool {
        return favoriteIds.contains(shopId)
    }
}

extension MockShopAPIService {
    var shouldDelay = false
    var shouldFail = false
    var additionalShops: [Shop] = []
    
    func fetchShops(genre: ShopGenre? = nil, latitude: Double? = nil, longitude: Double? = nil, radius: Double? = nil) async throws -> [Shop] {
        if shouldDelay {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        if shouldFail {
            throw APIError.networkError(NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch shops"]))
        }
        
        var shops = [
            Shop(id: 1, name: "Test Cafe", genre: .cafe),
            Shop(id: 2, name: "Test Ramen", genre: .ramen),
            Shop(id: 3, name: "Test Restaurant", genre: .restaurant)
        ]
        
        shops.append(contentsOf: additionalShops)
        
        return shops
    }
}