import XCTest

final class ShopDetailNavigationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Test shop card navigation from list view
    func testShopCardNavigationFromListView() throws {
        // Navigate to shop list
        let shopTabButton = app.tabBars.buttons["お店"]
        if shopTabButton.exists {
            shopTabButton.tap()
        }
        
        // Wait for shop list to load
        let shopListView = app.otherElements["ShopListView"]
        XCTAssertTrue(shopListView.waitForExistence(timeout: 5))
        
        // Ensure we're in list view (not map view)
        let listButton = app.buttons["リスト"]
        if listButton.exists && !listButton.isSelected {
            listButton.tap()
        }
        
        // Wait for shop cards to appear
        let shopScrollView = app.scrollViews["ShopListScrollView"]
        XCTAssertTrue(shopScrollView.waitForExistence(timeout: 5))
        
        // Find and tap the first shop card
        let firstShopCard = shopScrollView.buttons.matching(identifier: NSPredicate(format: "identifier BEGINSWITH 'ShopCard_'")).firstMatch
        if firstShopCard.exists {
            firstShopCard.tap()
            
            // Verify shop detail view appears
            let shopDetailView = app.navigationBars.buttons["閉じる"]
            XCTAssertTrue(shopDetailView.waitForExistence(timeout: 3), "Shop detail view should appear after tapping shop card")
            
            // Test back navigation
            shopDetailView.tap()
            
            // Verify we're back to the shop list
            XCTAssertTrue(shopListView.waitForExistence(timeout: 3), "Should return to shop list after closing detail")
        } else {
            XCTFail("No shop cards found in the list")
        }
    }
    
    // MARK: - Test map pin navigation
    func testMapPinNavigation() throws {
        // Navigate to shop list
        let shopTabButton = app.tabBars.buttons["お店"]
        if shopTabButton.exists {
            shopTabButton.tap()
        }
        
        // Wait for shop list to load
        let shopListView = app.otherElements["ShopListView"]
        XCTAssertTrue(shopListView.waitForExistence(timeout: 5))
        
        // Switch to map view
        let mapButton = app.buttons["マップ"]
        if mapButton.exists {
            mapButton.tap()
            
            // Wait for map to load
            let mapView = app.maps.firstMatch
            XCTAssertTrue(mapView.waitForExistence(timeout: 5))
            
            // Look for map annotations (pins)
            let annotations = mapView.otherElements.matching(NSPredicate(format: "elementType == %d", XCUIElement.ElementType.other.rawValue))
            
            if annotations.count > 0 {
                // Tap the first annotation
                let firstAnnotation = annotations.firstMatch
                firstAnnotation.tap()
                
                // Look for callout detail button
                let detailButton = mapView.buttons.matching(NSPredicate(format: "elementType == %d", XCUIElement.ElementType.button.rawValue)).firstMatch
                if detailButton.exists {
                    detailButton.tap()
                    
                    // Verify shop detail view appears
                    let shopDetailView = app.navigationBars.buttons["閉じる"]
                    XCTAssertTrue(shopDetailView.waitForExistence(timeout: 3), "Shop detail view should appear after tapping map pin")
                    
                    // Test back navigation
                    shopDetailView.tap()
                    
                    // Verify we're back to the map view
                    XCTAssertTrue(mapView.waitForExistence(timeout: 3), "Should return to map view after closing detail")
                }
            }
        }
    }
    
    // MARK: - Test navigation flow between list and map views
    func testNavigationFlowBetweenViews() throws {
        // Navigate to shop list
        let shopTabButton = app.tabBars.buttons["お店"]
        if shopTabButton.exists {
            shopTabButton.tap()
        }
        
        // Wait for shop list to load
        let shopListView = app.otherElements["ShopListView"]
        XCTAssertTrue(shopListView.waitForExistence(timeout: 5))
        
        // Test switching between list and map views
        let listButton = app.buttons["リスト"]
        let mapButton = app.buttons["マップ"]
        
        if listButton.exists && mapButton.exists {
            // Start in list view
            listButton.tap()
            let shopScrollView = app.scrollViews["ShopListScrollView"]
            XCTAssertTrue(shopScrollView.waitForExistence(timeout: 3))
            
            // Switch to map view
            mapButton.tap()
            let mapView = app.maps.firstMatch
            XCTAssertTrue(mapView.waitForExistence(timeout: 3))
            
            // Switch back to list view
            listButton.tap()
            XCTAssertTrue(shopScrollView.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Test shop detail view content
    func testShopDetailViewContent() throws {
        // Navigate to shop list and open a shop detail
        let shopTabButton = app.tabBars.buttons["お店"]
        if shopTabButton.exists {
            shopTabButton.tap()
        }
        
        let shopListView = app.otherElements["ShopListView"]
        XCTAssertTrue(shopListView.waitForExistence(timeout: 5))
        
        // Ensure we're in list view
        let listButton = app.buttons["リスト"]
        if listButton.exists {
            listButton.tap()
        }
        
        // Find and tap a shop card
        let shopScrollView = app.scrollViews["ShopListScrollView"]
        let firstShopCard = shopScrollView.buttons.matching(identifier: NSPredicate(format: "identifier BEGINSWITH 'ShopCard_'")).firstMatch
        
        if firstShopCard.exists {
            firstShopCard.tap()
            
            // Verify shop detail view content elements exist
            let closeButton = app.navigationBars.buttons["閉じる"]
            XCTAssertTrue(closeButton.waitForExistence(timeout: 3))
            
            // Look for common shop detail elements
            let scrollView = app.scrollViews.firstMatch
            XCTAssertTrue(scrollView.exists, "Shop detail should have a scroll view")
            
            // Test accessibility
            XCTAssertTrue(closeButton.isHittable, "Close button should be accessible")
            
            // Close the detail view
            closeButton.tap()
            XCTAssertTrue(shopListView.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Test swipe to dismiss gesture
    func testSwipeToDismissGesture() throws {
        // Navigate to shop list and open a shop detail
        let shopTabButton = app.tabBars.buttons["お店"]
        if shopTabButton.exists {
            shopTabButton.tap()
        }
        
        let shopListView = app.otherElements["ShopListView"]
        XCTAssertTrue(shopListView.waitForExistence(timeout: 5))
        
        // Open shop detail
        let shopScrollView = app.scrollViews["ShopListScrollView"]
        let firstShopCard = shopScrollView.buttons.matching(identifier: NSPredicate(format: "identifier BEGINSWITH 'ShopCard_'")).firstMatch
        
        if firstShopCard.exists {
            firstShopCard.tap()
            
            let closeButton = app.navigationBars.buttons["閉じる"]
            XCTAssertTrue(closeButton.waitForExistence(timeout: 3))
            
            // Try swipe down to dismiss (if supported)
            let detailView = app.scrollViews.firstMatch
            if detailView.exists {
                detailView.swipeDown()
                
                // Check if we're back to the list (swipe to dismiss worked)
                // If not, use the close button
                if !shopListView.waitForExistence(timeout: 1) {
                    closeButton.tap()
                }
                
                XCTAssertTrue(shopListView.waitForExistence(timeout: 3))
            }
        }
    }
    
    // MARK: - Performance test for navigation
    func testNavigationPerformance() throws {
        let shopTabButton = app.tabBars.buttons["お店"]
        if shopTabButton.exists {
            shopTabButton.tap()
        }
        
        let shopListView = app.otherElements["ShopListView"]
        XCTAssertTrue(shopListView.waitForExistence(timeout: 5))
        
        // Measure navigation performance
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let shopScrollView = app.scrollViews["ShopListScrollView"]
            let firstShopCard = shopScrollView.buttons.matching(identifier: NSPredicate(format: "identifier BEGINSWITH 'ShopCard_'")).firstMatch
            
            if firstShopCard.exists {
                firstShopCard.tap()
                
                let closeButton = app.navigationBars.buttons["閉じる"]
                _ = closeButton.waitForExistence(timeout: 3)
                
                closeButton.tap()
                _ = shopListView.waitForExistence(timeout: 3)
            }
        }
    }
}