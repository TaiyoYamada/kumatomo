import XCTest
import SwiftUI

final class SidebarUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Wait for app to load and authenticate if needed
        let homeTab = app.tabBars.buttons["ホーム"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: homeTab, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Sidebar Opening Tests (Requirement 3.1)
    
    func testSidebarOpensWithLeftEdgeSwipe() throws {
        // Given: App is on home screen with sidebar closed
        let homeTab = app.tabBars.buttons["ホーム"]
        homeTab.tap()
        
        // When: Swiping from left edge
        let leftEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let rightPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        leftEdge.press(forDuration: 0.1, thenDragTo: rightPoint)
        
        // Then: Sidebar should be visible
        let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
        XCTAssertTrue(sidebarPanel.waitForExistence(timeout: 2), "Sidebar should appear after left edge swipe")
    }
    
    func testSidebarOpensWithProfileIconTap() throws {
        // Given: App is on home screen
        let homeTab = app.tabBars.buttons["ホーム"]
        homeTab.tap()
        
        // When: Tapping profile icon (if available in navigation)
        // Note: This test assumes profile icon is accessible
        if app.buttons["profile_icon"].exists {
            app.buttons["profile_icon"].tap()
            
            // Then: Sidebar should be visible
            let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
            XCTAssertTrue(sidebarPanel.waitForExistence(timeout: 2), "Sidebar should appear after profile icon tap")
        }
    }
    
    func testSidebarOpeningAnimation() throws {
        // Given: App is on home screen
        let homeTab = app.tabBars.buttons["ホーム"]
        homeTab.tap()
        
        // When: Opening sidebar with swipe gesture
        let leftEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let rightPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        leftEdge.press(forDuration: 0.1, thenDragTo: rightPoint)
        
        // Then: Sidebar should animate smoothly (verified by existence after animation time)
        let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
        XCTAssertTrue(sidebarPanel.waitForExistence(timeout: 1), "Sidebar should animate in smoothly")
        
        // Verify sidebar is fully visible
        XCTAssertTrue(sidebarPanel.isHittable, "Sidebar should be fully interactive after animation")
    }
    
    // MARK: - Sidebar Closing Tests (Requirement 3.2)
    
    func testSidebarClosesWithLeftSwipe() throws {
        // Given: Sidebar is open
        try openSidebar()
        let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
        XCTAssertTrue(sidebarPanel.exists, "Sidebar should be open")
        
        // When: Swiping left on sidebar
        let rightPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        let leftPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        rightPoint.press(forDuration: 0.1, thenDragTo: leftPoint)
        
        // Then: Sidebar should close
        XCTAssertFalse(sidebarPanel.waitForExistence(timeout: 1), "Sidebar should close after left swipe")
    }
    
    func testSidebarClosesWithTapOutside() throws {
        // Given: Sidebar is open
        try openSidebar()
        let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
        XCTAssertTrue(sidebarPanel.exists, "Sidebar should be open")
        
        // When: Tapping outside sidebar (on overlay)
        let outsidePoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        outsidePoint.tap()
        
        // Then: Sidebar should close
        XCTAssertFalse(sidebarPanel.waitForExistence(timeout: 1), "Sidebar should close after tap outside")
    }
    
    func testSidebarClosingAnimation() throws {
        // Given: Sidebar is open
        try openSidebar()
        let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
        
        // When: Closing sidebar with tap outside
        let outsidePoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        outsidePoint.tap()
        
        // Then: Sidebar should animate out smoothly
        let disappeared = NSPredicate(format: "exists == false")
        expectation(for: disappeared, evaluatedWith: sidebarPanel, handler: nil)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK: - Tab Bar Visibility Tests (Requirements 1.3, 1.4, 3.5)
    
    func testTabBarHiddenWhenSidebarOpen() throws {
        // Given: App is on home screen with tab bar visible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should be visible initially")
        
        // When: Opening sidebar
        try openSidebar()
        
        // Then: Tab bar should be hidden or covered
        // Note: Since the sidebar covers the entire screen, the tab bar should not be hittable
        XCTAssertFalse(tabBar.isHittable, "Tab bar should not be interactive when sidebar is open")
    }
    
    func testTabBarVisibleWhenSidebarClosed() throws {
        // Given: Sidebar is open and tab bar is hidden
        try openSidebar()
        let tabBar = app.tabBars.firstMatch
        
        // When: Closing sidebar
        let outsidePoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        outsidePoint.tap()
        
        // Wait for sidebar to close
        let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
        let disappeared = NSPredicate(format: "exists == false")
        expectation(for: disappeared, evaluatedWith: sidebarPanel, handler: nil)
        waitForExpectations(timeout: 2, handler: nil)
        
        // Then: Tab bar should be visible and interactive again
        XCTAssertTrue(tabBar.isHittable, "Tab bar should be interactive when sidebar is closed")
    }
    
    func testTabBarVisibilityAnimationSmoothness() throws {
        // Given: App is on home screen
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should be visible initially")
        
        // When: Opening and closing sidebar multiple times
        for _ in 0..<3 {
            // Open sidebar
            try openSidebar()
            
            // Verify tab bar is not interactive
            XCTAssertFalse(tabBar.isHittable, "Tab bar should not be interactive when sidebar is open")
            
            // Close sidebar
            let outsidePoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            outsidePoint.tap()
            
            // Wait for close animation
            let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
            let disappeared = NSPredicate(format: "exists == false")
            expectation(for: disappeared, evaluatedWith: sidebarPanel, handler: nil)
            waitForExpectations(timeout: 1, handler: nil)
            
            // Verify tab bar is interactive again
            XCTAssertTrue(tabBar.isHittable, "Tab bar should be interactive when sidebar is closed")
        }
    }
    
    // MARK: - Full Screen Coverage Tests (Requirements 1.1, 1.3, 1.5)
    
    func testSidebarCoversEntireScreen() throws {
        // Given: Sidebar is open
        try openSidebar()
        let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
        
        // Then: Sidebar should cover the entire screen area
        let screenBounds = app.frame
        let sidebarFrame = sidebarPanel.frame
        
        // Verify sidebar extends to cover significant portion of screen
        XCTAssertGreaterThan(sidebarFrame.height, screenBounds.height * 0.9, 
                           "Sidebar should cover most of the screen height")
    }
    
    func testOverlayCoversEntireScreen() throws {
        // Given: Sidebar is open
        try openSidebar()
        
        // When: Tapping at various points outside sidebar
        let testPoints = [
            CGVector(dx: 0.9, dy: 0.1),  // Top right
            CGVector(dx: 0.9, dy: 0.5),  // Middle right
            CGVector(dx: 0.9, dy: 0.9),  // Bottom right
            CGVector(dx: 0.7, dy: 0.95)  // Near tab bar area
        ]
        
        for point in testPoints {
            // Open sidebar if not already open
            if !app.otherElements["twitter_sidebar_panel"].exists {
                try openSidebar()
            }
            
            // Tap at test point
            let tapPoint = app.coordinate(withNormalizedOffset: point)
            tapPoint.tap()
            
            // Then: Sidebar should close (indicating overlay covers that area)
            let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
            let disappeared = NSPredicate(format: "exists == false")
            expectation(for: disappeared, evaluatedWith: sidebarPanel, handler: nil)
            waitForExpectations(timeout: 1, handler: nil)
        }
    }
    
    // MARK: - Gesture Responsiveness Tests (Requirements 3.1, 3.2, 3.4)
    
    func testLeftEdgeGestureResponsiveness() throws {
        // Given: App is on home screen
        let homeTab = app.tabBars.buttons["ホーム"]
        homeTab.tap()
        
        // When: Testing various left edge swipe distances
        let testDistances: [CGFloat] = [0.3, 0.5, 0.8]
        
        for distance in testDistances {
            // Ensure sidebar is closed
            if app.otherElements["twitter_sidebar_panel"].exists {
                let outsidePoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
                outsidePoint.tap()
                
                let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
                let disappeared = NSPredicate(format: "exists == false")
                expectation(for: disappeared, evaluatedWith: sidebarPanel, handler: nil)
                waitForExpectations(timeout: 1, handler: nil)
            }
            
            // Swipe from left edge with varying distances
            let leftEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
            let rightPoint = app.coordinate(withNormalizedOffset: CGVector(dx: distance, dy: 0.5))
            leftEdge.press(forDuration: 0.1, thenDragTo: rightPoint)
            
            // Then: Sidebar should open for sufficient distances
            let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
            if distance >= 0.3 {
                XCTAssertTrue(sidebarPanel.waitForExistence(timeout: 1), 
                            "Sidebar should open for swipe distance \(distance)")
            }
        }
    }
    
    func testCloseGestureFromAnywhereOnScreen() throws {
        // Given: Sidebar is open
        try openSidebar()
        
        // When: Testing close gesture from various screen positions
        let testStartPoints = [
            CGVector(dx: 0.5, dy: 0.3),  // Center-left
            CGVector(dx: 0.7, dy: 0.5),  // Right side
            CGVector(dx: 0.6, dy: 0.8)   // Lower right
        ]
        
        for startPoint in testStartPoints {
            // Ensure sidebar is open
            if !app.otherElements["twitter_sidebar_panel"].exists {
                try openSidebar()
            }
            
            // Swipe left from test point
            let start = app.coordinate(withNormalizedOffset: startPoint)
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: startPoint.dx - 0.4, dy: startPoint.dy))
            start.press(forDuration: 0.1, thenDragTo: end)
            
            // Then: Sidebar should close
            let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
            let disappeared = NSPredicate(format: "exists == false")
            expectation(for: disappeared, evaluatedWith: sidebarPanel, handler: nil)
            waitForExpectations(timeout: 1, handler: nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func openSidebar() throws {
        let leftEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let rightPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        leftEdge.press(forDuration: 0.1, thenDragTo: rightPoint)
        
        let sidebarPanel = app.otherElements["twitter_sidebar_panel"]
        XCTAssertTrue(sidebarPanel.waitForExistence(timeout: 2), "Failed to open sidebar")
    }
}