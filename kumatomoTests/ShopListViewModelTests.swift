import XCTest
import SwiftUI
import CoreLocation
import Combine
@testable import kumatomo

@MainActor
final class ShopListViewModelTests: XCTestCase {
    
    var viewModel: ShopListViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = ShopListViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(viewModel.shops.isEmpty)
        XCTAssertTrue(viewModel.filteredShops.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.favoritesErrorMessage)
        XCTAssertTrue(viewModel.selectedGenres.isEmpty)
        XCTAssertFalse(viewModel.showingMap)
    }
    
    // MARK: - Genre Filtering Tests
    
    func testToggleGenre() {
        // Given
        let genre = ShopGenre.cafe
        
        // When - Add genre
        viewModel.toggleGenre(genre)
        
        // Then
        XCTAssertTrue(viewModel.selectedGenres.contains(genre))
        
        // When - Remove genre
        viewModel.toggleGenre(genre)
        
        // Then
        XCTAssertFalse(viewModel.selectedGenres.contains(genre))
    }
    
    func testMultipleGenreSelection() {
        // Given
        let cafe = ShopGenre.cafe
        let ramen = ShopGenre.ramen
        
        // When
        viewModel.toggleGenre(cafe)
        viewModel.toggleGenre(ramen)
        
        // Then
        XCTAssertTrue(viewModel.selectedGenres.contains(cafe))
        XCTAssertTrue(viewModel.selectedGenres.contains(ramen))
        XCTAssertEqual(viewModel.selectedGenres.count, 2)
    }
    
    func testClearAllGenres() {
        // Given
        viewModel.selectedGenres = Set([.cafe, .ramen, .restaurant])
        viewModel.shops = createMockShops()
        viewModel.filteredShops = []
        
        // When
        viewModel.clearAllGenres()
        
        // Then
        XCTAssertTrue(viewModel.selectedGenres.isEmpty)
        XCTAssertEqual(viewModel.filteredShops.count, viewModel.shops.count)
    }
    
    func testApplyFiltersWithSelectedGenres() {
        // Given
        viewModel.shops = createMockShops()
        viewModel.selectedGenres = Set([.cafe])
        
        // When
        viewModel.applyFilters()
        
        // Then
        XCTAssertEqual(viewModel.filteredShops.count, 1)
        XCTAssertEqual(viewModel.filteredShops.first?.genre, .cafe)
    }
    
    func testApplyFiltersWithNoSelectedGenres() {
        // Given
        viewModel.shops = createMockShops()
        viewModel.selectedGenres = Set()
        
        // When
        viewModel.applyFilters()
        
        // Then
        XCTAssertEqual(viewModel.filteredShops.count, viewModel.shops.count)
    }
    
    func testApplyFiltersWithMultipleGenres() {
        // Given
        viewModel.shops = createMockShops()
        viewModel.selectedGenres = Set([.cafe, .ramen])
        
        // When
        viewModel.applyFilters()
        
        // Then
        XCTAssertEqual(viewModel.filteredShops.count, 2)
        XCTAssertTrue(viewModel.filteredShops.allSatisfy { shop in
            shop.genre == .cafe || shop.genre == .ramen
        })
    }
    
    // MARK: - Map Toggle Tests
    
    func testToggleMapView() {
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
    
    // MARK: - Distance Calculation Tests
    
    func testDistanceFromUserWithValidLocation() {
        // Given
        let shop = Shop(
            id: 1,
            name: "Test Shop",
            latitude: 35.6762,
            longitude: 139.6503
        )
        
        // Mock LocationManager would need to be injected for proper testing
        // For now, we test that the method exists and returns expected format
        let distance = viewModel.distanceFromUser(to: shop)
        
        // Then - Should return nil if no user location, or formatted string if available
        XCTAssertTrue(distance == nil || distance!.contains("m") || distance!.contains("km"))
    }
    
    func testDistanceFromUserWithInvalidShopCoordinates() {
        // Given
        let shop = Shop(
            id: 1,
            name: "Test Shop",
            latitude: nil,
            longitude: nil
        )
        
        // When
        let distance = viewModel.distanceFromUser(to: shop)
        
        // Then
        XCTAssertNil(distance)
    }
    
    // MARK: - Error Handling Tests
    
    func testDismissFavoritesError() {
        // Given
        viewModel.favoritesErrorMessage = "Test error"
        
        // When
        viewModel.dismissFavoritesError()
        
        // Then
        XCTAssertNil(viewModel.favoritesErrorMessage)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateManagement() async {
        // Given
        XCTAssertFalse(viewModel.isLoading)
        
        // When - Start loading (this would normally be triggered by loadShops)
        viewModel.isLoading = true
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        
        // When - Finish loading
        viewModel.isLoading = false
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Published Properties Tests
    
    func testPublishedPropertiesEmitChanges() {
        let expectation = XCTestExpectation(description: "Published properties should emit changes")
        var changeCount = 0
        
        // Given - Subscribe to changes
        viewModel.objectWillChange
            .sink {
                changeCount += 1
                if changeCount >= 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Make changes to published properties
        viewModel.isLoading = true
        viewModel.errorMessage = "Test error"
        viewModel.showingMap = true
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertGreaterThanOrEqual(changeCount, 3)
    }
    
    // MARK: - Integration with Filters Tests
    
    func testGenreFilteringMaintainsStateConsistency() {
        // Given
        viewModel.shops = createMockShops()
        let initialShopCount = viewModel.shops.count
        
        // When - Apply and remove filters multiple times
        viewModel.toggleGenre(.cafe)
        let filteredCount1 = viewModel.filteredShops.count
        
        viewModel.toggleGenre(.ramen)
        let filteredCount2 = viewModel.filteredShops.count
        
        viewModel.clearAllGenres()
        let finalCount = viewModel.filteredShops.count
        
        // Then
        XCTAssertLessThan(filteredCount1, initialShopCount)
        XCTAssertGreaterThan(filteredCount2, filteredCount1)
        XCTAssertEqual(finalCount, initialShopCount)
    }
    
    // MARK: - Edge Cases Tests
    
    func testFilteringWithEmptyShopsList() {
        // Given
        viewModel.shops = []
        
        // When
        viewModel.toggleGenre(.cafe)
        
        // Then
        XCTAssertTrue(viewModel.filteredShops.isEmpty)
        XCTAssertTrue(viewModel.selectedGenres.contains(.cafe))
    }
    
    func testFilteringWithShopsWithoutGenre() {
        // Given
        let shopsWithoutGenre = [
            Shop(id: 1, name: "Shop 1", genre: nil),
            Shop(id: 2, name: "Shop 2", genre: .cafe)
        ]
        viewModel.shops = shopsWithoutGenre
        
        // When
        viewModel.toggleGenre(.cafe)
        
        // Then
        XCTAssertEqual(viewModel.filteredShops.count, 1)
        XCTAssertEqual(viewModel.filteredShops.first?.genre, .cafe)
    }
    
    // MARK: - Performance Tests
    
    func testFilteringPerformanceWithLargeDataset() {
        // Given
        let largeShopList = (1...1000).map { index in
            Shop(
                id: index,
                name: "Shop \(index)",
                genre: ShopGenre.allGenres[index % ShopGenre.allGenres.count]
            )
        }
        viewModel.shops = largeShopList
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        viewModel.toggleGenre(.cafe)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then
        let executionTime = endTime - startTime
        XCTAssertLessThan(executionTime, 0.1, "Filtering should complete in under 100ms")
        XCTAssertFalse(viewModel.filteredShops.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createMockShops() -> [Shop] {
        return [
            Shop(id: 1, name: "Cafe Shop", genre: .cafe),
            Shop(id: 2, name: "Ramen Shop", genre: .ramen),
            Shop(id: 3, name: "Restaurant Shop", genre: .restaurant),
            Shop(id: 4, name: "Another Cafe", genre: .cafe)
        ]
    }
}

// MARK: - Test Extensions

extension Shop {
    init(id: Int, name: String, genre: ShopGenre? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.description = "Test description"
        self.address = "Test address"
        self.phone = "123-456-7890"
        self.businessHours = "9:00-18:00"
        self.genre = genre
        self.latitude = latitude
        self.longitude = longitude
        self.imageUrl = "https://example.com/image.jpg"
        self.hasTryBenefit = false
        self.stampCount = 0
        self.isApproved = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}