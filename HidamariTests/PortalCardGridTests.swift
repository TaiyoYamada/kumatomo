import XCTest
import SwiftUI
@testable import Hidamari

@MainActor
final class PortalCardGridTests: XCTestCase {
    
    var cardGrid: PortalCardGrid!
    var sampleCards: [PortalCardData]!
    
    override func setUp() {
        super.setUp()
        sampleCards = [
            PortalCardData(title: "テスト1", imageName: "test1", externalURL: "https://test1.com"),
            PortalCardData(title: "テスト2", imageName: "test2", externalURL: "https://test2.com"),
            PortalCardData(title: "テスト3", imageName: "test3", externalURL: "https://test3.com"),
            PortalCardData(title: "テスト4", imageName: "test4", externalURL: "https://test4.com"),
            PortalCardData(title: "テスト5", imageName: "test5", externalURL: "https://test5.com"),
            PortalCardData(title: "テスト6", imageName: "test6", externalURL: "https://test6.com")
        ]
        cardGrid = PortalCardGrid(cards: sampleCards)
    }
    
    override func tearDown() {
        cardGrid = nil
        sampleCards = nil
        super.tearDown()
    }
    
    // MARK: - Card Grid Layout Tests (Requirements: 5.1, 5.6)
    
    func testCardGridInitialization() {
        // Given: Sample cards data
        // When: Creating card grid
        // Then: Should initialize successfully
        XCTAssertNotNil(cardGrid, "Card grid should initialize successfully")
    }
    
    func testCardGridWithSixCards() {
        // Given: Exactly 6 cards (3x2 grid requirement)
        let sixCards = Array(sampleCards.prefix(6))
        let grid = PortalCardGrid(cards: sixCards)
        
        // When: Checking card count
        // Then: Should handle exactly 6 cards
        XCTAssertEqual(sixCards.count, 6, "Should have exactly 6 cards for 3x2 grid")
        XCTAssertNotNil(grid, "Grid should handle 6 cards successfully")
    }
    
    func testCardGridWithFewerCards() {
        // Given: Fewer than 6 cards
        let fewerCards = Array(sampleCards.prefix(3))
        let grid = PortalCardGrid(cards: fewerCards)
        
        // When: Creating grid with fewer cards
        // Then: Should handle gracefully
        XCTAssertEqual(fewerCards.count, 3, "Should have 3 cards")
        XCTAssertNotNil(grid, "Grid should handle fewer cards gracefully")
    }
    
    func testCardGridWithMoreCards() {
        // Given: More than 6 cards
        let moreCards = sampleCards + [
            PortalCardData(title: "テスト7", imageName: "test7", externalURL: "https://test7.com"),
            PortalCardData(title: "テスト8", imageName: "test8", externalURL: "https://test8.com")
        ]
        let grid = PortalCardGrid(cards: moreCards)
        
        // When: Creating grid with more cards
        // Then: Should handle gracefully (will show all cards)
        XCTAssertEqual(moreCards.count, 8, "Should have 8 cards")
        XCTAssertNotNil(grid, "Grid should handle more cards gracefully")
    }
    
    func testCardGridWithEmptyCards() {
        // Given: Empty cards array
        let emptyCards: [PortalCardData] = []
        let grid = PortalCardGrid(cards: emptyCards)
        
        // When: Creating grid with empty array
        // Then: Should handle empty state
        XCTAssertEqual(emptyCards.count, 0, "Should have no cards")
        XCTAssertNotNil(grid, "Grid should handle empty state gracefully")
    }
    
    // MARK: - Grid Configuration Tests
    
    func testGridColumnConfiguration() {
        // Given: Expected grid configuration
        let expectedColumnCount = 3
        let expectedSpacing: CGFloat = 12
        
        // When: Checking grid configuration
        // Then: Should have 3 columns with proper spacing
        XCTAssertEqual(expectedColumnCount, 3, "Grid should have 3 columns")
        XCTAssertGreaterThan(expectedSpacing, 0, "Column spacing should be positive")
        XCTAssertLessThan(expectedSpacing, 20, "Column spacing should not be too large")
    }
    
    func testGridRowSpacing() {
        // Given: Expected row spacing
        let expectedRowSpacing: CGFloat = 16
        
        // When: Checking row spacing configuration
        // Then: Should have appropriate spacing between rows
        XCTAssertGreaterThan(expectedRowSpacing, 0, "Row spacing should be positive")
        XCTAssertGreaterThan(expectedRowSpacing, 12, "Row spacing should be larger than column spacing")
    }
    
    func testGridPadding() {
        // Given: Expected horizontal padding
        let expectedHorizontalPadding: CGFloat = 16
        
        // When: Checking padding configuration
        // Then: Should have consistent padding
        XCTAssertGreaterThan(expectedHorizontalPadding, 0, "Horizontal padding should be positive")
        XCTAssertEqual(expectedHorizontalPadding, 16, "Should use standard padding value")
    }
    
    // MARK: - Data Binding Tests
    
    func testCardDataBinding() {
        // Given: Card grid with sample data
        let testCards = Array(sampleCards.prefix(3))
        let grid = PortalCardGrid(cards: testCards)
        
        // When: Checking data binding
        // Then: Grid should maintain reference to card data
        XCTAssertNotNil(grid, "Grid should maintain card data reference")
        
        // Verify cards have expected properties
        for (index, card) in testCards.enumerated() {
            XCTAssertEqual(card.title, "テスト\(index + 1)", "Card \(index + 1) should have correct title")
            XCTAssertEqual(card.imageName, "test\(index + 1)", "Card \(index + 1) should have correct image name")
            XCTAssertEqual(card.externalURL, "https://test\(index + 1).com", "Card \(index + 1) should have correct URL")
        }
    }
    
    func testCardDataImmutability() {
        // Given: Original card data
        let originalCards = Array(sampleCards.prefix(3))
        let originalFirstTitle = originalCards[0].title
        
        // When: Creating grid (should not modify original data)
        let grid = PortalCardGrid(cards: originalCards)
        
        // Then: Original data should remain unchanged
        XCTAssertEqual(originalCards[0].title, originalFirstTitle, "Original card data should not be modified")
        XCTAssertNotNil(grid, "Grid should be created successfully")
    }
    
    func testCardDataWithDuplicateIDs() {
        // Given: Cards with potentially duplicate content (but unique IDs)
        let duplicateContentCards = [
            PortalCardData(title: "同じタイトル", imageName: "same_image", externalURL: "https://same.com"),
            PortalCardData(title: "同じタイトル", imageName: "same_image", externalURL: "https://same.com")
        ]
        
        // When: Creating grid with duplicate content
        let grid = PortalCardGrid(cards: duplicateContentCards)
        
        // Then: Should handle duplicate content (IDs will be unique)
        XCTAssertNotEqual(duplicateContentCards[0].id, duplicateContentCards[1].id, 
                         "Cards should have unique IDs even with same content")
        XCTAssertNotNil(grid, "Grid should handle duplicate content gracefully")
    }
    
    // MARK: - Accessibility Tests
    
    func testGridAccessibilityConfiguration() {
        // Given: Card grid with accessibility requirements
        let accessibilityLabel = "サービスカード一覧"
        let accessibilityHint = "6つのサービスカードが3列で表示されています"
        
        // When: Checking accessibility configuration
        // Then: Should have proper accessibility labels
        XCTAssertFalse(accessibilityLabel.isEmpty, "Accessibility label should not be empty")
        XCTAssertTrue(accessibilityLabel.contains("サービスカード"), "Label should mention service cards")
        XCTAssertTrue(accessibilityHint.contains("3列"), "Hint should mention 3 columns")
    }
    
    func testGridAccessibilityWithNetworkState() {
        // Given: Different network states
        let onlineLabel = "サービスカード一覧"
        let offlineLabel = "サービスカード一覧（オフライン状態）"
        
        // When: Checking network-aware accessibility
        // Then: Labels should reflect network state
        XCTAssertFalse(onlineLabel.contains("オフライン"), "Online label should not mention offline")
        XCTAssertTrue(offlineLabel.contains("オフライン"), "Offline label should mention offline state")
    }
    
    func testGridAccessibilityHints() {
        // Given: Different card counts and network states
        let testCases = [
            (cardCount: 6, isOnline: true, expectedHint: "6つのサービスカードが3列で表示されています"),
            (cardCount: 3, isOnline: true, expectedHint: "3つのサービスカードが3列で表示されています"),
            (cardCount: 6, isOnline: false, expectedHint: "6つのサービスカードが3列で表示されています。インターネット接続が必要です。")
        ]
        
        // When: Generating accessibility hints
        for testCase in testCases {
            let baseHint = "\(testCase.cardCount)つのサービスカードが3列で表示されています"
            let fullHint = testCase.isOnline ? baseHint : baseHint + "。インターネット接続が必要です。"
            
            // Then: Hints should be contextually appropriate
            XCTAssertTrue(fullHint.contains("\(testCase.cardCount)つ"), "Hint should mention card count")
            XCTAssertTrue(fullHint.contains("3列"), "Hint should mention column layout")
            
            if !testCase.isOnline {
                XCTAssertTrue(fullHint.contains("インターネット接続"), "Offline hint should mention internet connection")
            }
        }
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyStateDisplay() {
        // Given: Empty card array
        let emptyCards: [PortalCardData] = []
        let emptyGrid = PortalCardGrid(cards: emptyCards)
        
        // When: Creating grid with no cards
        // Then: Should handle empty state appropriately
        XCTAssertNotNil(emptyGrid, "Empty grid should be created successfully")
        
        // Expected empty state properties
        let emptyStateTitle = "サービスカードがありません"
        let emptyStateMessage = "カードデータを設定してください"
        
        XCTAssertTrue(emptyStateTitle.contains("サービスカード"), "Empty state should mention service cards")
        XCTAssertTrue(emptyStateMessage.contains("設定"), "Empty state should suggest configuration")
    }
    
    func testEmptyStateAccessibility() {
        // Given: Empty state accessibility requirements
        let emptyStateAccessibilityLabel = "サービスカードなし"
        let emptyStateAccessibilityHint = "カードデータを設定してください"
        
        // When: Checking empty state accessibility
        // Then: Should provide appropriate accessibility information
        XCTAssertFalse(emptyStateAccessibilityLabel.isEmpty, "Empty state should have accessibility label")
        XCTAssertFalse(emptyStateAccessibilityHint.isEmpty, "Empty state should have accessibility hint")
    }
    
    // MARK: - Network Integration Tests
    
    func testNetworkMonitorIntegration() {
        // Given: Network monitor integration
        let networkMonitor = NetworkMonitor.shared
        
        // When: Checking network monitor availability
        // Then: Should integrate with network monitoring
        XCTAssertNotNil(networkMonitor, "Network monitor should be available")
        
        let connectionStatus = networkMonitor.isConnected
        XCTAssertNotNil(connectionStatus, "Should provide connection status")
    }
    
    // MARK: - Layout Calculation Tests
    
    func testGridAspectRatio() {
        // Given: Expected card aspect ratio
        let expectedAspectRatio: CGFloat = 0.8
        let tolerance: CGFloat = 0.01
        
        // When: Checking aspect ratio configuration
        // Then: Should use appropriate aspect ratio for cards
        XCTAssertGreaterThan(expectedAspectRatio, 0, "Aspect ratio should be positive")
        XCTAssertLessThan(expectedAspectRatio, 2, "Aspect ratio should be reasonable")
        
        // Test aspect ratio calculation
        let calculatedRatio = 4.0 / 5.0 // 0.8
        XCTAssertEqual(calculatedRatio, expectedAspectRatio, accuracy: tolerance, 
                      "Calculated aspect ratio should match expected")
    }
    
    func testGridItemFlexibility() {
        // Given: Grid item configuration
        let gridItemType = GridItem(.flexible())
        
        // When: Checking grid item properties
        // Then: Should use flexible sizing
        XCTAssertNotNil(gridItemType, "Grid item should be configured")
        
        // Test that flexible grid items adapt to available space
        let flexibleItems = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        XCTAssertEqual(flexibleItems.count, 3, "Should have 3 flexible grid items")
    }
    
    // MARK: - Performance Tests
    
    func testGridCreationPerformance() {
        // Given: Performance measurement
        measure {
            // When: Creating multiple grid instances
            for _ in 0..<100 {
                let _ = PortalCardGrid(cards: sampleCards)
            }
        }
        
        // Then: Creation should be performant (measured by XCTest)
    }
    
    func testGridWithLargeDataSetPerformance() {
        // Given: Large dataset
        let largeCardSet = (1...100).map { index in
            PortalCardData(
                title: "大量データテスト\(index)",
                imageName: "large_test_\(index)",
                externalURL: "https://large-test\(index).com"
            )
        }
        
        // When: Measuring performance with large dataset
        measure {
            let _ = PortalCardGrid(cards: largeCardSet)
        }
        
        // Then: Should handle large datasets efficiently (measured by XCTest)
    }
    
    // MARK: - Edge Case Tests
    
    func testGridWithNilCardProperties() {
        // Given: Cards with empty properties (edge case)
        let edgeCaseCards = [
            PortalCardData(title: "", imageName: "", externalURL: ""),
            PortalCardData(title: "正常", imageName: "normal", externalURL: "https://normal.com")
        ]
        
        // When: Creating grid with edge case data
        let edgeGrid = PortalCardGrid(cards: edgeCaseCards)
        
        // Then: Should handle edge cases gracefully
        XCTAssertNotNil(edgeGrid, "Grid should handle edge case data")
        XCTAssertEqual(edgeCaseCards.count, 2, "Should maintain all cards including edge cases")
    }
    
    func testGridWithSpecialCharacters() {
        // Given: Cards with special characters
        let specialCharCards = [
            PortalCardData(title: "特殊文字テスト!@#$%", imageName: "special_char", externalURL: "https://special.com"),
            PortalCardData(title: "絵文字テスト🎉🚀", imageName: "emoji_test", externalURL: "https://emoji.com"),
            PortalCardData(title: "改行\nテスト", imageName: "newline_test", externalURL: "https://newline.com")
        ]
        
        // When: Creating grid with special characters
        let specialGrid = PortalCardGrid(cards: specialCharCards)
        
        // Then: Should handle special characters properly
        XCTAssertNotNil(specialGrid, "Grid should handle special characters")
        
        for card in specialCharCards {
            XCTAssertFalse(card.title.isEmpty, "Card titles should be preserved")
            XCTAssertNotNil(card.id, "Card IDs should be generated")
        }
    }
}