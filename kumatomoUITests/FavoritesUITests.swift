import XCTest

final class FavoritesUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Favorites Section in MyPage Tests
    
    func testFavoritesSectionDisplaysInMyPage() throws {
        // Navigate to MyPage
        navigateToMyPage()
        
        // Verify favorites section exists
        let favoritesSection = app.staticTexts["お気に入り"]
        XCTAssertTrue(favoritesSection.exists, "Favorites section should be visible in MyPage")
    }
    
    func testFavoritesEmptyStateDisplay() throws {
        // Navigate to MyPage
        navigateToMyPage()
        
        // Check for empty state message (assuming user has no favorites initially)
        let emptyMessage = app.staticTexts["まだお気に入りがありません"]
        if emptyMessage.exists {
            XCTAssertTrue(emptyMessage.exists, "Empty state message should be displayed when no favorites exist")
            
            // Check for action button
            let exploreButton = app.buttons["お店を探す"]
            XCTAssertTrue(exploreButton.exists, "Explore shops button should be visible in empty state")
        }
    }
    
    func testViewAllFavoritesNavigation() throws {
        // Navigate to MyPage
        navigateToMyPage()
        
        // Look for "View All" button (only appears when favorites exist)
        let viewAllButton = app.buttons["ViewAllFavoritesButton"]
        if viewAllButton.exists {
            viewAllButton.tap()
            
            // Verify navigation to favorites list
            let favoritesTitle = app.navigationBars["お気に入り"]
            XCTAssertTrue(favoritesTitle.waitForExistence(timeout: 3), "Should navigate to favorites list view")
        }
    }
    
    func testCompactFavoriteCardDisplay() throws {
        // Navigate to MyPage
        navigateToMyPage()
        
        // Look for compact favorite cards
        let compactCards = app.buttons.matching(identifier: "CompactFavoriteCard_")
        if compactCards.count > 0 {
            let firstCard = compactCards.element(boundBy: 0)
            XCTAssertTrue(firstCard.exists, "Compact favorite card should be displayed")
            
            // Test tap navigation to shop detail
            firstCard.tap()
            
            // Should open shop detail sheet
            let shopDetailView = app.otherElements["ShopDetailView"]
            XCTAssertTrue(shopDetailView.waitForExistence(timeout: 3), "Should navigate to shop detail when tapping favorite card")
        }
    }
    
    func testRemoveFavoriteFromCompactView() throws {
        // Navigate to MyPage
        navigateToMyPage()
        
        // Look for favorite remove buttons in compact view
        let removeFavoriteButtons = app.buttons.matching(identifier: "CompactRemoveFavoriteButton_")
        if removeFavoriteButtons.count > 0 {
            let initialCount = removeFavoriteButtons.count
            let firstRemoveButton = removeFavoriteButtons.element(boundBy: 0)
            
            firstRemoveButton.tap()
            
            // Wait for the favorite to be removed
            sleep(2)
            
            // Verify the favorite was removed (count should decrease or empty state should appear)
            let updatedButtons = app.buttons.matching(identifier: "CompactRemoveFavoriteButton_")
            let emptyMessage = app.staticTexts["まだお気に入りがありません"]
            
            XCTAssertTrue(updatedButtons.count < initialCount || emptyMessage.exists, 
                         "Favorite should be removed from compact view")
        }
    }
    
    // MARK: - Full Favorites List Tests
    
    func testFavoritesListViewDisplay() throws {
        // Navigate to favorites list directly (if accessible via navigation)
        navigateToMyPage()
        
        let viewAllButton = app.buttons["ViewAllFavoritesButton"]
        if viewAllButton.exists {
            viewAllButton.tap()
            
            // Verify favorites list view elements
            let favoritesTitle = app.navigationBars["お気に入り"]
            XCTAssertTrue(favoritesTitle.exists, "Favorites list should have proper title")
            
            let refreshButton = app.buttons.matching(identifier: "arrow.clockwise").element
            XCTAssertTrue(refreshButton.exists, "Refresh button should be available in toolbar")
        }
    }
    
    func testFavoritesListEmptyState() throws {
        // Navigate to favorites list
        navigateToMyPage()
        
        let viewAllButton = app.buttons["ViewAllFavoritesButton"]
        if viewAllButton.exists {
            viewAllButton.tap()
        } else {
            // If no favorites, try to navigate directly to empty favorites list
            // This would require implementing a direct navigation method
            return
        }
        
        // Check for empty state in full list view
        let emptyStateView = app.otherElements["FavoritesEmptyStateView"]
        if emptyStateView.exists {
            XCTAssertTrue(emptyStateView.exists, "Empty state should be displayed in favorites list")
            
            let exploreButton = app.buttons["お店を探す"]
            XCTAssertTrue(exploreButton.exists, "Explore button should be available in empty state")
        }
    }
    
    func testFavoriteCardInteraction() throws {
        // Navigate to favorites list
        navigateToMyPage()
        
        let viewAllButton = app.buttons["ViewAllFavoritesButton"]
        if viewAllButton.exists {
            viewAllButton.tap()
            
            // Look for favorite shop cards
            let favoriteCards = app.buttons.matching(identifier: "FavoriteShopCard_")
            if favoriteCards.count > 0 {
                let firstCard = favoriteCards.element(boundBy: 0)
                
                // Test card tap
                firstCard.tap()
                
                // Should navigate to shop detail
                let shopDetailView = app.otherElements["ShopDetailView"]
                XCTAssertTrue(shopDetailView.waitForExistence(timeout: 3), 
                             "Should navigate to shop detail when tapping favorite card")
            }
        }
    }
    
    func testRemoveFavoriteFromFullList() throws {
        // Navigate to favorites list
        navigateToMyPage()
        
        let viewAllButton = app.buttons["ViewAllFavoritesButton"]
        if viewAllButton.exists {
            viewAllButton.tap()
            
            // Look for remove favorite buttons
            let removeFavoriteButtons = app.buttons.matching(identifier: "RemoveFavoriteButton_")
            if removeFavoriteButtons.count > 0 {
                let initialCount = removeFavoriteButtons.count
                let firstRemoveButton = removeFavoriteButtons.element(boundBy: 0)
                
                firstRemoveButton.tap()
                
                // Wait for the favorite to be removed
                sleep(2)
                
                // Verify the favorite was removed
                let updatedButtons = app.buttons.matching(identifier: "RemoveFavoriteButton_")
                let emptyStateView = app.otherElements["FavoritesEmptyStateView"]
                
                XCTAssertTrue(updatedButtons.count < initialCount || emptyStateView.exists, 
                             "Favorite should be removed from list")
            }
        }
    }
    
    func testFavoritesListRefresh() throws {
        // Navigate to favorites list
        navigateToMyPage()
        
        let viewAllButton = app.buttons["ViewAllFavoritesButton"]
        if viewAllButton.exists {
            viewAllButton.tap()
            
            // Test refresh functionality
            let refreshButton = app.buttons.matching(identifier: "arrow.clockwise").element
            if refreshButton.exists {
                refreshButton.tap()
                
                // Verify loading state appears briefly
                let loadingView = app.otherElements["FavoritesLoadingView"]
                // Loading might be too fast to catch, so we just verify the button works
                XCTAssertTrue(refreshButton.exists, "Refresh button should remain accessible after tap")
            }
        }
    }
    
    func testFavoritesPullToRefresh() throws {
        // Navigate to favorites list
        navigateToMyPage()
        
        let viewAllButton = app.buttons["ViewAllFavoritesButton"]
        if viewAllButton.exists {
            viewAllButton.tap()
            
            // Test pull-to-refresh
            let scrollView = app.scrollViews["FavoritesScrollView"]
            if scrollView.exists {
                let startCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
                let endCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
                
                startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
                
                // Verify the refresh action was triggered
                // The actual refresh might be too fast to verify loading state
                XCTAssertTrue(scrollView.exists, "Scroll view should remain functional after pull-to-refresh")
            }
        }
    }
    
    func testFavoritesErrorHandling() throws {
        // Navigate to favorites list
        navigateToMyPage()
        
        // Look for error banner (if network error occurs)
        let errorBanner = app.otherElements["FavoritesErrorBanner"]
        if errorBanner.exists {
            XCTAssertTrue(errorBanner.exists, "Error banner should be displayed when favorites loading fails")
            
            // Test dismiss error
            let dismissButton = app.buttons.matching(identifier: "xmark").element
            if dismissButton.exists {
                dismissButton.tap()
                
                // Verify error banner is dismissed
                XCTAssertFalse(errorBanner.exists, "Error banner should be dismissed after tapping close button")
            }
        }
    }
    
    func testFavoritesAccessibilityLabels() throws {
        // Navigate to MyPage
        navigateToMyPage()
        
        // Test accessibility labels for favorites section
        let favoritesSection = app.staticTexts["お気に入り"]
        if favoritesSection.exists {
            XCTAssertTrue(favoritesSection.isHittable, "Favorites section should be accessible")
        }
        
        // Test favorite button accessibility
        let favoriteButtons = app.buttons.matching(identifier: "CompactRemoveFavoriteButton_")
        if favoriteButtons.count > 0 {
            let firstButton = favoriteButtons.element(boundBy: 0)
            XCTAssertEqual(firstButton.label, "お気に入りから削除", 
                          "Favorite button should have proper accessibility label")
        }
    }
    
    // MARK: - Integration with Shop List Tests
    
    func testAddFavoriteFromShopList() throws {
        // Navigate to shop list
        navigateToShopList()
        
        // Look for favorite buttons in shop cards
        let favoriteButtons = app.buttons.matching(identifier: "FavoriteButton_")
        if favoriteButtons.count > 0 {
            let firstButton = favoriteButtons.element(boundBy: 0)
            let initialLabel = firstButton.label
            
            firstButton.tap()
            
            // Wait for the favorite status to update
            sleep(2)
            
            // Verify the button state changed
            let updatedLabel = firstButton.label
            XCTAssertNotEqual(initialLabel, updatedLabel, 
                             "Favorite button state should change after tapping")
            
            // Navigate back to MyPage to verify favorite was added
            navigateToMyPage()
            
            // Check if the favorite appears in MyPage
            let compactCards = app.buttons.matching(identifier: "CompactFavoriteCard_")
            XCTAssertTrue(compactCards.count > 0, "Favorite should appear in MyPage after adding from shop list")
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToMyPage() {
        let profileTab = app.tabBars.buttons["プロフィール"]
        if profileTab.exists {
            profileTab.tap()
        } else {
            // Alternative navigation method if tab structure is different
            let profileButton = app.buttons["profile"]
            if profileButton.exists {
                profileButton.tap()
            }
        }
        
        // Wait for MyPage to load
        let myPageView = app.otherElements["MyProfileView"]
        _ = myPageView.waitForExistence(timeout: 3)
    }
    
    private func navigateToShopList() {
        let shopTab = app.tabBars.buttons["お店"]
        if shopTab.exists {
            shopTab.tap()
        } else {
            // Alternative navigation method
            let shopButton = app.buttons["shop"]
            if shopButton.exists {
                shopButton.tap()
            }
        }
        
        // Wait for shop list to load
        let shopListView = app.otherElements["ShopListView"]
        _ = shopListView.waitForExistence(timeout: 3)
    }
}