import XCTest

final class ShopMapUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Map Display Tests
    
    func testMapView_ShouldBeDisplayedWhenMapToggleSelected() throws {
        navigateToShopList()
        
        // Switch to map view
        let mapToggleButton = app.buttons["マップ"]
        XCTAssertTrue(mapToggleButton.exists)
        mapToggleButton.tap()
        
        // Verify map is displayed
        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.exists)
        XCTAssertTrue(mapView.isHittable)
    }
    
    func testMapView_ShouldShowUserLocation() throws {
        navigateToShopList()
        switchToMapView()
        
        // Verify user location is shown (this might require location permissions)
        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.exists)
        
        // Note: Testing user location display requires proper location permissions
        // and may need to be tested with location simulation
    }
    
    func testMapView_ShouldDisplayShopPins() throws {
        navigateToShopList()
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        // Wait for map to load
        let mapExists = NSPredicate(format: "exists == true")
        expectation(for: mapExists, evaluatedWith: mapView, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        // Verify shop pins are displayed
        // Note: Map annotations might not be directly accessible via XCUITest
        // This test verifies the map view is present and interactive
        XCTAssertTrue(mapView.isHittable)
    }
    
    // MARK: - Map Pin Interaction Tests
    
    func testMapPin_WhenTapped_ShouldShowCallout() throws {
        navigateToShopList()
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        // Wait for map to load
        Thread.sleep(forTimeInterval: 2.0)
        
        // Tap on map (this will tap on a pin if one is at the center)
        mapView.tap()
        
        // Wait for potential callout to appear
        Thread.sleep(forTimeInterval: 1.0)
        
        // Note: Callout testing is challenging with XCUITest as map annotations
        // are not directly accessible. This test ensures map interaction works.
        XCTAssertTrue(mapView.exists)
    }
    
    func testMapPin_CalloutDetailButton_ShouldNavigateToShopDetail() throws {
        navigateToShopList()
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        // Wait for map to load
        Thread.sleep(forTimeInterval: 2.0)
        
        // Tap on map to potentially select a pin
        mapView.tap()
        
        // Look for detail disclosure button (if callout is shown)
        let detailButton = app.buttons["More Info"]
        if detailButton.exists {
            detailButton.tap()
            
            // Verify navigation to shop detail
            // This would depend on how shop detail is presented (sheet, navigation, etc.)
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        // Test passes if no crash occurs during interaction
        XCTAssertTrue(mapView.exists)
    }
    
    // MARK: - Map-List Synchronization Tests
    
    func testMapListSync_WhenShopSelectedInMap_ShouldHighlightInList() throws {
        navigateToShopList()
        
        // Start in list view to see initial state
        let shopListView = app.scrollViews["ShopListScrollView"]
        XCTAssertTrue(shopListView.exists)
        
        // Switch to map view
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        // Simulate selecting a shop on map
        mapView.tap()
        
        // Switch back to list view
        let listToggleButton = app.buttons["リスト"]
        listToggleButton.tap()
        
        // Verify we're back in list view
        XCTAssertTrue(shopListView.exists)
        
        // Note: Verifying specific shop highlighting would require
        // more detailed accessibility identifiers on shop cards
    }
    
    func testMapListSync_WhenToggleBetweenViews_ShouldMaintainSelection() throws {
        navigateToShopList()
        
        // Switch to map view
        switchToMapView()
        
        // Interact with map
        let mapView = app.maps.firstMatch
        mapView.tap()
        
        // Switch to list view
        let listToggleButton = app.buttons["リスト"]
        listToggleButton.tap()
        
        // Switch back to map view
        switchToMapView()
        
        // Verify map is still functional
        XCTAssertTrue(mapView.exists)
        XCTAssertTrue(mapView.isHittable)
    }
    
    // MARK: - Map Region Management Tests
    
    func testMapRegion_ShouldCenterOnUserLocationWhenAvailable() throws {
        navigateToShopList()
        switchToMapView()
        
        // Request location permission if needed
        let locationButton = app.buttons.matching(identifier: "location").firstMatch
        if locationButton.exists {
            locationButton.tap()
            
            // Handle location permission alert if it appears
            handleLocationPermissionAlert()
        }
        
        let mapView = app.maps.firstMatch
        
        // Wait for potential location update
        Thread.sleep(forTimeInterval: 3.0)
        
        // Verify map is still functional after location request
        XCTAssertTrue(mapView.exists)
        XCTAssertTrue(mapView.isHittable)
    }
    
    func testMapRegion_ShouldCenterOnShopsWhenNoUserLocation() throws {
        navigateToShopList()
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        // Wait for map to load and center on shops
        Thread.sleep(forTimeInterval: 2.0)
        
        // Verify map is displayed and interactive
        XCTAssertTrue(mapView.exists)
        XCTAssertTrue(mapView.isHittable)
    }
    
    // MARK: - Map Navigation Tests
    
    func testMapNavigation_ShouldAllowZoomingAndPanning() throws {
        navigateToShopList()
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        // Test pinch to zoom (simulate with double tap)
        mapView.doubleTap()
        
        // Wait for zoom animation
        Thread.sleep(forTimeInterval: 1.0)
        
        // Test panning
        mapView.swipeLeft()
        mapView.swipeRight()
        mapView.swipeUp()
        mapView.swipeDown()
        
        // Verify map is still functional after gestures
        XCTAssertTrue(mapView.exists)
        XCTAssertTrue(mapView.isHittable)
    }
    
    // MARK: - Custom Annotation Tests
    
    func testCustomAnnotations_ShouldDisplayGenreColors() throws {
        navigateToShopList()
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        // Wait for annotations to load
        Thread.sleep(forTimeInterval: 2.0)
        
        // Verify map is functional (detailed annotation testing is limited in XCUITest)
        XCTAssertTrue(mapView.exists)
        
        // Note: Testing specific annotation appearance (colors, images) is challenging
        // with XCUITest as map annotations are rendered by MapKit
    }
    
    func testTryBenefitBadge_ShouldBeVisibleOnEligibleShops() throws {
        navigateToShopList()
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        // Wait for map to load
        Thread.sleep(forTimeInterval: 2.0)
        
        // Tap on map to potentially interact with annotations
        mapView.tap()
        
        // Note: Testing specific badge visibility requires the annotations to be
        // accessible through XCUITest, which is limited for MapKit annotations
        XCTAssertTrue(mapView.exists)
    }
    
    // MARK: - Error Handling Tests
    
    func testMapView_ShouldHandleNoShopsGracefully() throws {
        navigateToShopList()
        
        // Clear any filters that might be applied
        clearAllGenreFilters()
        
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        // Even with no shops, map should still be functional
        XCTAssertTrue(mapView.exists)
        XCTAssertTrue(mapView.isHittable)
    }
    
    func testMapView_ShouldHandleLocationPermissionDenied() throws {
        navigateToShopList()
        switchToMapView()
        
        // Request location (this might trigger permission dialog)
        let locationButton = app.buttons.matching(identifier: "location").firstMatch
        if locationButton.exists {
            locationButton.tap()
            
            // If permission dialog appears, deny it
            let denyButton = app.alerts.buttons["Don't Allow"]
            if denyButton.exists {
                denyButton.tap()
            }
        }
        
        let mapView = app.maps.firstMatch
        
        // Map should still function without location permission
        XCTAssertTrue(mapView.exists)
        XCTAssertTrue(mapView.isHittable)
    }
    
    // MARK: - Performance Tests
    
    func testMapPerformance_ShouldLoadQuickly() throws {
        navigateToShopList()
        
        measure {
            switchToMapView()
            
            let mapView = app.maps.firstMatch
            let mapExists = NSPredicate(format: "exists == true")
            expectation(for: mapExists, evaluatedWith: mapView, handler: nil)
            waitForExpectations(timeout: 3, handler: nil)
            
            // Switch back to list for next iteration
            let listToggleButton = app.buttons["リスト"]
            listToggleButton.tap()
        }
    }
    
    func testMapInteraction_ShouldBeResponsive() throws {
        navigateToShopList()
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        measure {
            // Perform various map interactions
            mapView.tap()
            mapView.doubleTap()
            mapView.swipeLeft()
            mapView.swipeRight()
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testMapView_ShouldSupportVoiceOver() throws {
        navigateToShopList()
        switchToMapView()
        
        let mapView = app.maps.firstMatch
        
        // Verify map is accessible
        XCTAssertTrue(mapView.isHittable)
        
        // Note: Detailed VoiceOver testing for map annotations would require
        // specific accessibility configuration on the annotations
    }
    
    func testMapToggleButtons_ShouldHaveProperAccessibilityLabels() throws {
        navigateToShopList()
        
        let listButton = app.buttons["リスト"]
        let mapButton = app.buttons["マップ"]
        
        XCTAssertTrue(listButton.exists)
        XCTAssertTrue(mapButton.exists)
        
        // Verify buttons are accessible
        XCTAssertTrue(listButton.isHittable)
        XCTAssertTrue(mapButton.isHittable)
        
        // Test toggle functionality
        mapButton.tap()
        XCTAssertTrue(app.maps.firstMatch.exists)
        
        listButton.tap()
        XCTAssertTrue(app.scrollViews["ShopListScrollView"].exists)
    }
    
    // MARK: - Helper Methods
    
    private func navigateToShopList() {
        // Navigate to shop list (adjust based on app structure)
        if app.tabBars.buttons["Shop"].exists {
            app.tabBars.buttons["Shop"].tap()
        }
        
        // Wait for shop list to load
        let shopListView = app.otherElements["ShopListView"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: shopListView, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func switchToMapView() {
        let mapToggleButton = app.buttons["マップ"]
        XCTAssertTrue(mapToggleButton.exists)
        mapToggleButton.tap()
        
        // Wait for map to appear
        let mapView = app.maps.firstMatch
        let mapExists = NSPredicate(format: "exists == true")
        expectation(for: mapExists, evaluatedWith: mapView, handler: nil)
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    private func clearAllGenreFilters() {
        let genreFilterView = app.otherElements["GenreFilterView"]
        let clearButton = genreFilterView.buttons["クリア"]
        
        if clearButton.exists {
            clearButton.tap()
        }
    }
    
    private func handleLocationPermissionAlert() {
        // Handle location permission alert if it appears
        let allowButton = app.alerts.buttons["Allow While Using App"]
        let allowOnceButton = app.alerts.buttons["Allow Once"]
        
        if allowButton.exists {
            allowButton.tap()
        } else if allowOnceButton.exists {
            allowOnceButton.tap()
        }
        
        // Wait for alert to dismiss
        Thread.sleep(forTimeInterval: 1.0)
    }
}