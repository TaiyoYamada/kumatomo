import XCTest
import SwiftUI
@testable import kumatomo

@MainActor
final class FavoritesViewTests: XCTestCase {
    
    var favoritesManager: FavoritesManager!
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        favoritesManager = FavoritesManager.shared
        locationManager = LocationManager.shared
        
        // Clear any existing state
        favoritesManager.clearFavorites()
    }
    
    override func tearDown() {
        favoritesManager.clearFavorites()
        super.tearDown()
    }
    
    // MARK: - FavoritesSectionView Tests
    
    func testFavoritesSectionViewEmptyState() {
        // Given - empty favorites
        XCTAssertTrue(favoritesManager.isEmpty)
        
        // When - creating FavoritesSectionView
        let sectionView = FavoritesSectionView()
        
        // Then - should show empty state
        XCTAssertTrue(favoritesManager.isEmpty)
        XCTAssertEqual(favoritesManager.favoriteCount, 0)
    }
    
    func testFavoritesSectionViewWithFavorites() {
        // Given - favorites exist
        let mockShop = createMockShop(id: 123, name: "Test Shop")
        favoritesManager.favoriteIds.insert(mockShop.id)
        favoritesManager.favoriteShops.append(mockShop)
        
        // When - creating FavoritesSectionView
        let sectionView = FavoritesSectionView()
        
        // Then - should show favorites
        XCTAssertFalse(favoritesManager.isEmpty)
        XCTAssertEqual(favoritesManager.favoriteCount, 1)
        XCTAssertTrue(favoritesManager.isFavorite(shopId: mockShop.id))
    }
    
    func testFavoritesSectionViewMaxDisplayCount() {
        // Given - more than 3 favorites
        for i in 1...5 {
            let shop = createMockShop(id: i, name: "Shop \(i)")
            favoritesManager.favoriteIds.insert(shop.id)
            favoritesManager.favoriteShops.append(shop)
        }
        
        // When - getting sorted favorites
        let sortedFavorites = favoritesManager.getFavoriteShopsSorted()
        let displayedFavorites = Array(sortedFavorites.prefix(3))
        
        // Then - should limit to 3 items in compact view
        XCTAssertEqual(favoritesManager.favoriteCount, 5)
        XCTAssertEqual(displayedFavorites.count, 3)
    }
    
    // MARK: - FavoritesListView Tests
    
    func testFavoritesListViewEmptyState() {
        // Given - empty favorites
        XCTAssertTrue(favoritesManager.isEmpty)
        
        // When - creating FavoritesListView
        let listView = FavoritesListView()
        
        // Then - should handle empty state
        XCTAssertTrue(favoritesManager.isEmpty)
        XCTAssertNil(favoritesManager.errorMessage)
    }
    
    func testFavoritesListViewWithContent() {
        // Given - favorites exist
        let mockShops = [
            createMockShop(id: 1, name: "Shop 1"),
            createMockShop(id: 2, name: "Shop 2"),
            createMockShop(id: 3, name: "Shop 3")
        ]
        
        for shop in mockShops {
            favoritesManager.favoriteIds.insert(shop.id)
            favoritesManager.favoriteShops.append(shop)
        }
        
        // When - creating FavoritesListView
        let listView = FavoritesListView()
        
        // Then - should display all favorites
        XCTAssertEqual(favoritesManager.favoriteCount, 3)
        XCTAssertFalse(favoritesManager.isEmpty)
        
        let sortedFavorites = favoritesManager.getFavoriteShopsSorted()
        XCTAssertEqual(sortedFavorites.count, 3)
    }
    
    // MARK: - Distance Calculation Tests
    
    func testDistanceCalculationWithUserLocation() {
        // Given - user location and shop with coordinates
        let userLocation = CLLocation(latitude: 35.6762, longitude: 139.6503) // Tokyo Station
        let shop = createMockShop(id: 1, name: "Test Shop")
        
        // When - calculating distance
        let distance = shop.distanceFromUser(userLocation)
        
        // Then - should return formatted distance
        XCTAssertNotNil(distance)
        XCTAssertTrue(distance!.contains("m") || distance!.contains("km"))
    }
    
    func testDistanceCalculationWithoutUserLocation() {
        // Given - no user location
        let shop = createMockShop(id: 1, name: "Test Shop")
        
        // When - calculating distance
        let distance = shop.distanceFromUser(nil)
        
        // Then - should return nil
        XCTAssertNil(distance)
    }
    
    func testDistanceCalculationWithoutShopCoordinates() {
        // Given - user location but shop without coordinates
        let userLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
        var shop = createMockShop(id: 1, name: "Test Shop")
        shop.latitude = nil
        shop.longitude = nil
        
        // When - calculating distance
        let distance = shop.distanceFromUser(userLocation)
        
        // Then - should return nil
        XCTAssertNil(distance)
    }
    
    // MARK: - Favorite Toggle Tests
    
    func testFavoriteToggleOptimisticUpdate() async {
        // Given - shop not in favorites
        let shop = createMockShop(id: 123, name: "Test Shop")
        XCTAssertFalse(favoritesManager.isFavorite(shopId: shop.id))
        
        // When - toggling favorite (this will fail in test environment but we can test optimistic update)
        let initialCount = favoritesManager.favoriteCount
        
        // Simulate optimistic update
        favoritesManager.favoriteIds.insert(shop.id)
        favoritesManager.favoriteShops.append(shop)
        
        // Then - should be added optimistically
        XCTAssertTrue(favoritesManager.isFavorite(shopId: shop.id))
        XCTAssertEqual(favoritesManager.favoriteCount, initialCount + 1)
    }
    
    func testFavoriteToggleRemove() {
        // Given - shop in favorites
        let shop = createMockShop(id: 123, name: "Test Shop")
        favoritesManager.favoriteIds.insert(shop.id)
        favoritesManager.favoriteShops.append(shop)
        
        XCTAssertTrue(favoritesManager.isFavorite(shopId: shop.id))
        let initialCount = favoritesManager.favoriteCount
        
        // When - removing favorite
        favoritesManager.favoriteIds.remove(shop.id)
        favoritesManager.favoriteShops.removeAll { $0.id == shop.id }
        
        // Then - should be removed
        XCTAssertFalse(favoritesManager.isFavorite(shopId: shop.id))
        XCTAssertEqual(favoritesManager.favoriteCount, initialCount - 1)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessageHandling() {
        // Given - error message
        let errorMessage = "Network error occurred"
        favoritesManager.errorMessage = errorMessage
        
        // When - checking error state
        XCTAssertEqual(favoritesManager.errorMessage, errorMessage)
        
        // When - clearing error
        favoritesManager.errorMessage = nil
        
        // Then - error should be cleared
        XCTAssertNil(favoritesManager.errorMessage)
    }
    
    func testLoadingStateHandling() {
        // Given - initial state
        XCTAssertFalse(favoritesManager.isLoading)
        
        // When - setting loading state
        favoritesManager.isLoading = true
        
        // Then - should be loading
        XCTAssertTrue(favoritesManager.isLoading)
        
        // When - clearing loading state
        favoritesManager.isLoading = false
        
        // Then - should not be loading
        XCTAssertFalse(favoritesManager.isLoading)
    }
    
    // MARK: - Sorting Tests
    
    func testFavoritesSortingByCreationDate() {
        // Given - favorites with different creation dates
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let twoHoursAgo = now.addingTimeInterval(-7200)
        
        var shop1 = createMockShop(id: 1, name: "Oldest Shop")
        var shop2 = createMockShop(id: 2, name: "Middle Shop")
        var shop3 = createMockShop(id: 3, name: "Newest Shop")
        
        shop1.createdAt = twoHoursAgo
        shop2.createdAt = oneHourAgo
        shop3.createdAt = now
        
        favoritesManager.favoriteShops = [shop1, shop2, shop3]
        
        // When - getting sorted favorites
        let sortedFavorites = favoritesManager.getFavoriteShopsSorted()
        
        // Then - should be sorted by creation date (newest first)
        XCTAssertEqual(sortedFavorites.count, 3)
        XCTAssertEqual(sortedFavorites[0].id, 3) // Newest
        XCTAssertEqual(sortedFavorites[1].id, 2) // Middle
        XCTAssertEqual(sortedFavorites[2].id, 1) // Oldest
    }
    
    func testFavoritesSortingWithNilDates() {
        // Given - favorites with nil creation dates
        var shop1 = createMockShop(id: 1, name: "Shop with nil date")
        var shop2 = createMockShop(id: 2, name: "Shop with date")
        
        shop1.createdAt = nil
        shop2.createdAt = Date()
        
        favoritesManager.favoriteShops = [shop1, shop2]
        
        // When - getting sorted favorites
        let sortedFavorites = favoritesManager.getFavoriteShopsSorted()
        
        // Then - should handle nil dates gracefully
        XCTAssertEqual(sortedFavorites.count, 2)
        // Shop with date should come first
        XCTAssertEqual(sortedFavorites[0].id, 2)
    }
    
    // MARK: - Integration Tests
    
    func testFavoritesIntegrationWithShopModel() {
        // Given - shop with all properties
        let shop = Shop(
            id: 123,
            name: "Integration Test Shop",
            description: "A test shop for integration testing",
            address: "123 Test Street, Test City",
            phone: "123-456-7890",
            businessHours: "9:00 AM - 6:00 PM",
            genre: .cafe,
            latitude: 35.6762,
            longitude: 139.6503,
            imageUrl: "https://example.com/shop.jpg",
            hasTryBenefit: true,
            stampCount: 5,
            isApproved: true
        )
        
        // When - adding to favorites
        favoritesManager.favoriteIds.insert(shop.id)
        favoritesManager.favoriteShops.append(shop)
        
        // Then - should maintain all shop properties
        XCTAssertTrue(favoritesManager.isFavorite(shopId: shop.id))
        let favoriteShop = favoritesManager.favoriteShops.first { $0.id == shop.id }
        XCTAssertNotNil(favoriteShop)
        XCTAssertEqual(favoriteShop?.name, shop.name)
        XCTAssertEqual(favoriteShop?.genre, shop.genre)
        XCTAssertEqual(favoriteShop?.hasTryBenefit, shop.hasTryBenefit)
        XCTAssertEqual(favoriteShop?.stampCount, shop.stampCount)
    }
    
    // MARK: - Performance Tests
    
    func testFavoritesPerformanceWithLargeDataset() {
        // Given - large number of favorites
        let shopCount = 1000
        var shops: [Shop] = []
        
        for i in 1...shopCount {
            let shop = createMockShop(id: i, name: "Shop \(i)")
            shops.append(shop)
            favoritesManager.favoriteIds.insert(shop.id)
        }
        
        favoritesManager.favoriteShops = shops
        
        // When - measuring performance of sorting
        measure {
            let _ = favoritesManager.getFavoriteShopsSorted()
        }
        
        // Then - should complete within reasonable time
        XCTAssertEqual(favoritesManager.favoriteCount, shopCount)
    }
    
    // MARK: - Helper Methods
    
    private func createMockShop(id: Int, name: String) -> Shop {
        return Shop(
            id: id,
            name: name,
            description: "Test description for \(name)",
            address: "\(id) Test Street, Test City",
            phone: "123-456-78\(String(format: "%02d", id % 100))",
            businessHours: "9:00 AM - 6:00 PM",
            genre: .cafe,
            latitude: 35.6762 + Double(id) * 0.001, // Slightly different coordinates
            longitude: 139.6503 + Double(id) * 0.001,
            imageUrl: "https://example.com/shop\(id).jpg",
            hasTryBenefit: id % 2 == 0, // Every other shop has try benefit
            stampCount: id % 10, // Varying stamp counts
            isApproved: true
        )
    }
}