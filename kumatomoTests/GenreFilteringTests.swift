import XCTest
import SwiftUI
@testable import kumatomo

@MainActor
final class GenreFilteringTests: XCTestCase {
    
    var viewModel: ShopListViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ShopListViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Genre Selection Tests
    
    func testToggleGenre_WhenGenreNotSelected_ShouldAddToSelection() {
        // Given
        let genre = ShopGenre.cafe
        XCTAssertFalse(viewModel.selectedGenres.contains(genre))
        
        // When
        viewModel.toggleGenre(genre)
        
        // Then
        XCTAssertTrue(viewModel.selectedGenres.contains(genre))
    }
    
    func testToggleGenre_WhenGenreAlreadySelected_ShouldRemoveFromSelection() {
        // Given
        let genre = ShopGenre.ramen
        viewModel.selectedGenres.insert(genre)
        XCTAssertTrue(viewModel.selectedGenres.contains(genre))
        
        // When
        viewModel.toggleGenre(genre)
        
        // Then
        XCTAssertFalse(viewModel.selectedGenres.contains(genre))
    }
    
    func testToggleMultipleGenres_ShouldMaintainAllSelections() {
        // Given
        let genres: [ShopGenre] = [.cafe, .ramen, .restaurant]
        
        // When
        for genre in genres {
            viewModel.toggleGenre(genre)
        }
        
        // Then
        for genre in genres {
            XCTAssertTrue(viewModel.selectedGenres.contains(genre))
        }
        XCTAssertEqual(viewModel.selectedGenres.count, 3)
    }
    
    func testClearAllGenres_ShouldRemoveAllSelections() {
        // Given
        viewModel.selectedGenres = [.cafe, .ramen, .restaurant]
        XCTAssertEqual(viewModel.selectedGenres.count, 3)
        
        // When
        viewModel.clearAllGenres()
        
        // Then
        XCTAssertTrue(viewModel.selectedGenres.isEmpty)
    }
    
    // MARK: - Filter Application Tests
    
    func testApplyFilters_WhenNoGenresSelected_ShouldShowAllShops() {
        // Given
        let shops = createMockShops()
        viewModel.shops = shops
        viewModel.selectedGenres = []
        
        // When
        viewModel.applyFilters()
        
        // Then
        XCTAssertEqual(viewModel.filteredShops.count, shops.count)
        XCTAssertEqual(viewModel.filteredShops, shops)
    }
    
    func testApplyFilters_WhenSingleGenreSelected_ShouldShowOnlyMatchingShops() {
        // Given
        let shops = createMockShops()
        viewModel.shops = shops
        viewModel.selectedGenres = [.cafe]
        
        // When
        viewModel.applyFilters()
        
        // Then
        let expectedShops = shops.filter { $0.genre == .cafe }
        XCTAssertEqual(viewModel.filteredShops.count, expectedShops.count)
        XCTAssertEqual(viewModel.filteredShops, expectedShops)
    }
    
    func testApplyFilters_WhenMultipleGenresSelected_ShouldShowShopsMatchingAnyGenre() {
        // Given
        let shops = createMockShops()
        viewModel.shops = shops
        viewModel.selectedGenres = [.cafe, .ramen]
        
        // When
        viewModel.applyFilters()
        
        // Then
        let expectedShops = shops.filter { shop in
            guard let genre = shop.genre else { return false }
            return viewModel.selectedGenres.contains(genre)
        }
        XCTAssertEqual(viewModel.filteredShops.count, expectedShops.count)
        XCTAssertEqual(viewModel.filteredShops, expectedShops)
    }
    
    func testApplyFilters_WhenShopHasNoGenre_ShouldNotBeIncludedInFilteredResults() {
        // Given
        let shops = [
            Shop(id: 1, name: "Shop 1", genre: .cafe),
            Shop(id: 2, name: "Shop 2", genre: nil),
            Shop(id: 3, name: "Shop 3", genre: .ramen)
        ]
        viewModel.shops = shops
        viewModel.selectedGenres = [.cafe, .ramen]
        
        // When
        viewModel.applyFilters()
        
        // Then
        XCTAssertEqual(viewModel.filteredShops.count, 2)
        XCTAssertFalse(viewModel.filteredShops.contains { $0.id == 2 })
    }
    
    // MARK: - Integration Tests
    
    func testGenreFilteringWorkflow_CompleteUserJourney() {
        // Given
        let shops = createMockShops()
        viewModel.shops = shops
        
        // When: User selects cafe genre
        viewModel.toggleGenre(.cafe)
        
        // Then: Only cafe shops should be visible
        let cafeShops = shops.filter { $0.genre == .cafe }
        XCTAssertEqual(viewModel.filteredShops.count, cafeShops.count)
        
        // When: User adds ramen genre
        viewModel.toggleGenre(.ramen)
        
        // Then: Both cafe and ramen shops should be visible
        let cafeAndRamenShops = shops.filter { shop in
            shop.genre == .cafe || shop.genre == .ramen
        }
        XCTAssertEqual(viewModel.filteredShops.count, cafeAndRamenShops.count)
        
        // When: User removes cafe genre
        viewModel.toggleGenre(.cafe)
        
        // Then: Only ramen shops should be visible
        let ramenShops = shops.filter { $0.genre == .ramen }
        XCTAssertEqual(viewModel.filteredShops.count, ramenShops.count)
        
        // When: User clears all filters
        viewModel.clearAllGenres()
        
        // Then: All shops should be visible
        XCTAssertEqual(viewModel.filteredShops.count, shops.count)
    }
    
    // MARK: - Helper Methods
    
    private func createMockShops() -> [Shop] {
        return [
            Shop(id: 1, name: "Cafe A", genre: .cafe),
            Shop(id: 2, name: "Ramen B", genre: .ramen),
            Shop(id: 3, name: "Restaurant C", genre: .restaurant),
            Shop(id: 4, name: "Cafe D", genre: .cafe),
            Shop(id: 5, name: "Izakaya E", genre: .izakaya),
            Shop(id: 6, name: "Ramen F", genre: .ramen),
            Shop(id: 7, name: "Sweets G", genre: .sweets),
            Shop(id: 8, name: "Bar H", genre: .bar)
        ]
    }
}

// MARK: - ShopListViewModel Extension for Testing
extension ShopListViewModel {
    func applyFilters() {
        if selectedGenres.isEmpty {
            filteredShops = shops
        } else {
            filteredShops = shops.filter { shop in
                guard let shopGenre = shop.genre else { return false }
                return selectedGenres.contains(shopGenre)
            }
        }
    }
}