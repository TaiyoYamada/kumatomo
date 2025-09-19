import XCTest

final class GenreChipUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Genre Chip Display Tests
    
    func testGenreChips_ShouldBeDisplayedHorizontally() throws {
        // Navigate to shop list
        navigateToShopList()
        
        // Verify genre filter section exists
        let genreFilterView = app.otherElements["GenreFilterView"]
        XCTAssertTrue(genreFilterView.exists)
        
        // Verify horizontal scroll view exists
        let genreScrollView = genreFilterView.scrollViews.firstMatch
        XCTAssertTrue(genreScrollView.exists)
        
        // Verify at least some genre chips are visible
        let genreChips = genreScrollView.buttons
        XCTAssertGreaterThan(genreChips.count, 0)
    }
    
    func testGenreChips_ShouldDisplayCorrectGenreNames() throws {
        navigateToShopList()
        
        let genreScrollView = app.otherElements["GenreFilterView"].scrollViews.firstMatch
        
        // Check for some expected genre names
        let expectedGenres = ["カフェ", "ラーメン", "レストラン", "居酒屋", "スイーツ"]
        
        for genreName in expectedGenres {
            let genreChip = genreScrollView.buttons[genreName]
            XCTAssertTrue(genreChip.exists, "Genre chip for '\(genreName)' should exist")
        }
    }
    
    func testGenreChips_ShouldBeScrollableHorizontally() throws {
        navigateToShopList()
        
        let genreScrollView = app.otherElements["GenreFilterView"].scrollViews.firstMatch
        
        // Get initial visible chips
        let initialChips = genreScrollView.buttons.allElementsBoundByIndex
        let initialChipNames = initialChips.map { $0.label }
        
        // Scroll to the right
        genreScrollView.swipeLeft()
        
        // Wait for scroll animation
        Thread.sleep(forTimeInterval: 0.5)
        
        // Get chips after scrolling
        let afterScrollChips = genreScrollView.buttons.allElementsBoundByIndex
        let afterScrollChipNames = afterScrollChips.map { $0.label }
        
        // Verify that different chips are now visible (indicating scroll worked)
        XCTAssertNotEqual(initialChipNames, afterScrollChipNames, "Scrolling should reveal different genre chips")
    }
    
    // MARK: - Genre Selection Tests
    
    func testGenreChip_WhenTapped_ShouldChangeVisualState() throws {
        navigateToShopList()
        
        let genreScrollView = app.otherElements["GenreFilterView"].scrollViews.firstMatch
        let cafeChip = genreScrollView.buttons["カフェ"]
        
        // Verify chip exists and is initially unselected
        XCTAssertTrue(cafeChip.exists)
        XCTAssertFalse(cafeChip.isSelected)
        
        // Tap the chip
        cafeChip.tap()
        
        // Verify chip is now selected
        XCTAssertTrue(cafeChip.isSelected)
    }
    
    func testMultipleGenreChips_WhenTapped_ShouldAllowMultipleSelections() throws {
        navigateToShopList()
        
        let genreScrollView = app.otherElements["GenreFilterView"].scrollViews.firstMatch
        let cafeChip = genreScrollView.buttons["カフェ"]
        let ramenChip = genreScrollView.buttons["ラーメン"]
        
        // Select both chips
        cafeChip.tap()
        ramenChip.tap()
        
        // Verify both are selected
        XCTAssertTrue(cafeChip.isSelected)
        XCTAssertTrue(ramenChip.isSelected)
    }
    
    func testGenreChip_WhenTappedTwice_ShouldToggleSelection() throws {
        navigateToShopList()
        
        let genreScrollView = app.otherElements["GenreFilterView"].scrollViews.firstMatch
        let cafeChip = genreScrollView.buttons["カフェ"]
        
        // First tap - should select
        cafeChip.tap()
        XCTAssertTrue(cafeChip.isSelected)
        
        // Second tap - should deselect
        cafeChip.tap()
        XCTAssertFalse(cafeChip.isSelected)
    }
    
    // MARK: - Clear All Functionality Tests
    
    func testClearButton_WhenGenresSelected_ShouldBeVisible() throws {
        navigateToShopList()
        
        let genreFilterView = app.otherElements["GenreFilterView"]
        let genreScrollView = genreFilterView.scrollViews.firstMatch
        let cafeChip = genreScrollView.buttons["カフェ"]
        
        // Initially, clear button should not be visible
        let clearButton = genreFilterView.buttons["クリア"]
        XCTAssertFalse(clearButton.exists)
        
        // Select a genre
        cafeChip.tap()
        
        // Clear button should now be visible
        XCTAssertTrue(clearButton.exists)
    }
    
    func testClearButton_WhenTapped_ShouldDeselectAllGenres() throws {
        navigateToShopList()
        
        let genreFilterView = app.otherElements["GenreFilterView"]
        let genreScrollView = genreFilterView.scrollViews.firstMatch
        let cafeChip = genreScrollView.buttons["カフェ"]
        let ramenChip = genreScrollView.buttons["ラーメン"]
        
        // Select multiple genres
        cafeChip.tap()
        ramenChip.tap()
        
        // Verify selections
        XCTAssertTrue(cafeChip.isSelected)
        XCTAssertTrue(ramenChip.isSelected)
        
        // Tap clear button
        let clearButton = genreFilterView.buttons["クリア"]
        clearButton.tap()
        
        // Verify all selections are cleared
        XCTAssertFalse(cafeChip.isSelected)
        XCTAssertFalse(ramenChip.isSelected)
        
        // Clear button should no longer be visible
        XCTAssertFalse(clearButton.exists)
    }
    
    // MARK: - Filter Application Tests
    
    func testGenreFilter_WhenApplied_ShouldUpdateShopList() throws {
        navigateToShopList()
        
        // Get initial shop count
        let shopList = app.scrollViews["ShopListScrollView"]
        let initialShopCards = shopList.buttons.matching(identifier: "ShopCard").count
        
        // Select a specific genre
        let genreScrollView = app.otherElements["GenreFilterView"].scrollViews.firstMatch
        let cafeChip = genreScrollView.buttons["カフェ"]
        cafeChip.tap()
        
        // Wait for filter to be applied
        Thread.sleep(forTimeInterval: 1.0)
        
        // Get filtered shop count
        let filteredShopCards = shopList.buttons.matching(identifier: "ShopCard").count
        
        // Verify that filtering has occurred (count should be different, likely less)
        // Note: This assumes there are shops with different genres in the test data
        XCTAssertNotEqual(initialShopCards, filteredShopCards, "Shop list should change when filter is applied")
    }
    
    // MARK: - Accessibility Tests
    
    func testGenreChips_ShouldHaveProperAccessibilityLabels() throws {
        navigateToShopList()
        
        let genreScrollView = app.otherElements["GenreFilterView"].scrollViews.firstMatch
        let cafeChip = genreScrollView.buttons["カフェ"]
        
        // Verify accessibility label
        XCTAssertEqual(cafeChip.label, "カフェ")
        
        // Verify accessibility hint changes based on selection state
        let initialHint = cafeChip.value as? String
        
        cafeChip.tap()
        
        let selectedHint = cafeChip.value as? String
        XCTAssertNotEqual(initialHint, selectedHint, "Accessibility hint should change when chip is selected")
    }
    
    func testGenreChips_ShouldSupportVoiceOver() throws {
        navigateToShopList()
        
        let genreScrollView = app.otherElements["GenreFilterView"].scrollViews.firstMatch
        let cafeChip = genreScrollView.buttons["カフェ"]
        
        // Verify chip is accessible
        XCTAssertTrue(cafeChip.isHittable)
        
        // Verify chip has proper traits
        XCTAssertTrue(cafeChip.elementType == .button)
    }
    
    // MARK: - Performance Tests
    
    func testGenreChipScrolling_ShouldBeSmooth() throws {
        navigateToShopList()
        
        let genreScrollView = app.otherElements["GenreFilterView"].scrollViews.firstMatch
        
        // Measure scrolling performance
        measure {
            for _ in 0..<5 {
                genreScrollView.swipeLeft()
                genreScrollView.swipeRight()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToShopList() {
        // Assuming the app starts on a tab view and shop list is accessible
        // This might need to be adjusted based on the actual app navigation structure
        
        // If there's a tab bar, tap on the shop tab
        if app.tabBars.buttons["Shop"].exists {
            app.tabBars.buttons["Shop"].tap()
        }
        
        // Wait for the shop list to load
        let shopListView = app.otherElements["ShopListView"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: shopListView, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
}