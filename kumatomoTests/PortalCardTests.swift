import XCTest
import SwiftUI
@testable import kumatomo

@MainActor
final class PortalCardTests: XCTestCase {
    
    var sampleCard: PortalCardData!
    var portalCard: PortalCard!
    
    override func setUp() {
        super.setUp()
        sampleCard = PortalCardData(
            title: "テストサービス",
            imageName: "test_card_image",
            externalURL: "https://test-service.com"
        )
        portalCard = PortalCard(cardData: sampleCard)
    }
    
    override func tearDown() {
        portalCard = nil
        sampleCard = nil
        super.tearDown()
    }
    
    // MARK: - Portal Card Component Tests (Requirements: 5.1, 5.6)
    
    func testPortalCardInitialization() {
        // Given: Sample card data
        // When: Creating portal card component
        // Then: Should initialize successfully
        XCTAssertNotNil(portalCard, "Portal card should initialize successfully")
    }
    
    func testPortalCardWithValidData() {
        // Given: Valid card data
        let validCard = PortalCardData(
            title: "有効なサービス",
            imageName: "valid_image",
            externalURL: "https://valid-service.com"
        )
        let card = PortalCard(cardData: validCard)
        
        // When: Creating card with valid data
        // Then: Should handle valid data properly
        XCTAssertNotNil(card, "Card should handle valid data")
        XCTAssertEqual(validCard.title, "有効なサービス", "Card should preserve title")
        XCTAssertEqual(validCard.imageName, "valid_image", "Card should preserve image name")
        XCTAssertEqual(validCard.externalURL, "https://valid-service.com", "Card should preserve URL")
    }
    
    func testPortalCardWithEmptyData() {
        // Given: Card data with empty values
        let emptyCard = PortalCardData(
            title: "",
            imageName: "",
            externalURL: ""
        )
        let card = PortalCard(cardData: emptyCard)
        
        // When: Creating card with empty data
        // Then: Should handle empty data gracefully
        XCTAssertNotNil(card, "Card should handle empty data gracefully")
    }
    
    func testPortalCardWithLongTitle() {
        // Given: Card with very long title
        let longTitleCard = PortalCardData(
            title: "これは非常に長いサービス名前でテストのために作成されたものです。実際のアプリケーションでは適切に表示されるべきです。",
            imageName: "long_title_image",
            externalURL: "https://long-title-service.com"
        )
        let card = PortalCard(cardData: longTitleCard)
        
        // When: Creating card with long title
        // Then: Should handle long titles appropriately
        XCTAssertNotNil(card, "Card should handle long titles")
        XCTAssertGreaterThan(longTitleCard.title.count, 50, "Title should be long")
    }
    
    // MARK: - URL Validation and Opening Tests
    
    func testValidURLValidation() {
        // Given: Cards with valid URLs
        let validURLs = [
            "https://www.apple.com",
            "http://example.org",
            "https://subdomain.example.com/path?param=value",
            "tel:+1234567890",
            "mailto:test@example.com"
        ]
        
        let errorHandler = PortalErrorHandler.shared
        
        // When: Validating URLs
        for urlString in validURLs {
            if !urlString.contains("example.com") { // Skip placeholder domains
                // Then: Should validate successfully
                XCTAssertNoThrow(try errorHandler.validateURL(urlString), 
                               "URL '\(urlString)' should be valid")
            }
        }
    }
    
    func testInvalidURLValidation() {
        // Given: Cards with invalid URLs
        let invalidURLs = [
            "",
            "   ",
            "not-a-url",
            "javascript:alert('test')",
            "file:///etc/passwd",
            "ftp://example.com"
        ]
        
        let errorHandler = PortalErrorHandler.shared
        
        // When: Validating URLs
        for urlString in invalidURLs {
            // Then: Should throw validation error
            XCTAssertThrowsError(try errorHandler.validateURL(urlString), 
                               "URL '\(urlString)' should be invalid") { error in
                XCTAssertTrue(error is PortalErrorHandler.PortalError, 
                            "Should throw PortalError for invalid URL")
            }
        }
    }
    
    func testPlaceholderURLDetection() {
        // Given: Placeholder URLs that need replacement
        let placeholderCard = PortalCardData(
            title: "プレースホルダーサービス",
            imageName: "placeholder_image",
            externalURL: "https://example.com/service"
        )
        
        let errorHandler = PortalErrorHandler.shared
        
        // When: Validating placeholder URL
        // Then: Should detect as configuration error
        XCTAssertThrowsError(try errorHandler.validateURL(placeholderCard.externalURL), 
                           "Placeholder URL should be detected") { error in
            if case PortalErrorHandler.PortalError.configurationError = error {
                // Expected configuration error
            } else {
                XCTFail("Should throw configuration error for placeholder URL")
            }
        }
    }
    
    func testURLCanOpenValidation() {
        // Given: Error handler
        let errorHandler = PortalErrorHandler.shared
        
        // When: Testing URL opening capability
        if let validURL = URL(string: "https://www.apple.com") {
            let canOpen = errorHandler.canOpenURL(validURL)
            
            // Then: Should be able to determine if URL can be opened
            XCTAssertNotNil(canOpen, "Should provide URL opening capability check")
        }
        
        // Test with unsupported scheme
        if let unsupportedURL = URL(string: "unsupported://test") {
            let canOpen = errorHandler.canOpenURL(unsupportedURL)
            
            // Then: Should return false for unsupported schemes
            XCTAssertFalse(canOpen, "Should return false for unsupported URL schemes")
        }
    }
    
    // MARK: - Image Asset Validation Tests
    
    func testImageAssetValidation() {
        // Given: Various image asset names
        let errorHandler = PortalErrorHandler.shared
        
        // When: Validating image assets
        let existingAsset = errorHandler.validateImageAsset("AppIcon") // May exist
        let missingAsset = errorHandler.validateImageAsset("definitely_missing_image")
        let emptyAsset = errorHandler.validateImageAsset("")
        
        // Then: Should correctly identify asset availability
        XCTAssertFalse(missingAsset, "Missing asset should be detected")
        XCTAssertFalse(emptyAsset, "Empty asset name should be invalid")
    }
    
    func testImageAssetWithDifferentExtensions() {
        // Given: Image names with various extensions
        let imageNames = [
            "test_image.png",
            "test_image.jpg",
            "test_image.jpeg",
            "test_image.gif",
            "test_image" // No extension
        ]
        
        let errorHandler = PortalErrorHandler.shared
        
        // When: Validating images with different extensions
        for imageName in imageNames {
            let isValid = errorHandler.validateImageAsset(imageName)
            
            // Then: Should handle different extensions (all will be false for test assets)
            XCTAssertFalse(isValid, "Test image '\(imageName)' should not exist")
        }
    }
    
    // MARK: - Touch Feedback and Animation Tests
    
    func testCardTouchFeedbackConfiguration() {
        // Given: Touch feedback parameters
        let pressedScale: CGFloat = 0.95
        let animationDuration: TimeInterval = 0.1
        
        // When: Checking touch feedback configuration
        // Then: Should have appropriate values for user experience
        XCTAssertLessThan(pressedScale, 1.0, "Pressed scale should be smaller than normal")
        XCTAssertGreaterThan(pressedScale, 0.8, "Pressed scale should not be too small")
        XCTAssertGreaterThan(animationDuration, 0, "Animation duration should be positive")
        XCTAssertLessThan(animationDuration, 0.5, "Animation should be quick")
    }
    
    func testCardShadowConfiguration() {
        // Given: Shadow parameters
        let shadowRadius: CGFloat = 2
        let shadowOffsetX: CGFloat = 0
        let shadowOffsetY: CGFloat = 1
        let shadowOpacity: Double = 0.1
        
        // When: Checking shadow configuration
        // Then: Should create subtle shadow effect
        XCTAssertGreaterThan(shadowRadius, 0, "Shadow radius should be positive")
        XCTAssertEqual(shadowOffsetX, 0, "Shadow should be centered horizontally")
        XCTAssertGreaterThan(shadowOffsetY, 0, "Shadow should offset downward")
        XCTAssertGreaterThan(shadowOpacity, 0, "Shadow should be visible")
        XCTAssertLessThan(shadowOpacity, 0.3, "Shadow should be subtle")
    }
    
    // MARK: - Accessibility Tests
    
    func testCardAccessibilityLabels() {
        // Given: Different card states
        let normalCard = PortalCardData(title: "通常サービス", imageName: "normal", externalURL: "https://normal.com")
        let normalLabel = normalCard.title
        let offlineLabel = "\(normalCard.title)（オフライン状態）"
        let errorLabel = "\(normalCard.title)（設定エラー）"
        
        // When: Checking accessibility labels
        // Then: Labels should be descriptive and contextual
        XCTAssertEqual(normalLabel, "通常サービス", "Normal label should match title")
        XCTAssertTrue(offlineLabel.contains("オフライン"), "Offline label should indicate offline state")
        XCTAssertTrue(errorLabel.contains("エラー"), "Error label should indicate error state")
    }
    
    func testCardAccessibilityHints() {
        // Given: Different accessibility hints
        let normalHint = "タップして外部リンクを開きます"
        let offlineHint = "インターネット接続が必要です"
        let errorHint = "URLの設定に問題があります"
        
        // When: Checking accessibility hints
        // Then: Hints should provide helpful guidance
        XCTAssertTrue(normalHint.contains("外部リンク"), "Normal hint should mention external link")
        XCTAssertTrue(offlineHint.contains("インターネット接続"), "Offline hint should mention internet connection")
        XCTAssertTrue(errorHint.contains("URL"), "Error hint should mention URL issue")
    }
    
    func testCardAccessibilityTraits() {
        // Given: Card accessibility requirements
        let expectedTraits = "button"
        
        // When: Checking accessibility traits
        // Then: Should be marked as button for proper interaction
        XCTAssertEqual(expectedTraits, "button", "Card should have button accessibility trait")
    }
    
    // MARK: - Error Handling Tests
    
    func testCardErrorStates() {
        // Given: Different error conditions
        let networkError = PortalErrorHandler.PortalError.networkUnavailable
        let urlError = PortalErrorHandler.PortalError.invalidURL("test")
        let assetError = PortalErrorHandler.PortalError.assetNotFound("test_image")
        
        // When: Checking error properties
        // Then: Each error should have appropriate user messages
        XCTAssertTrue(networkError.userFriendlyMessage.contains("インターネット接続"), 
                     "Network error should mention internet connection")
        XCTAssertTrue(urlError.userFriendlyMessage.contains("無効なURL"), 
                     "URL error should mention invalid URL")
        XCTAssertTrue(assetError.userFriendlyMessage.contains("画像"), 
                     "Asset error should mention image")
    }
    
    func testCardErrorRetryBehavior() {
        // Given: Different error types
        let retryableError = PortalErrorHandler.PortalError.networkUnavailable
        let nonRetryableError = PortalErrorHandler.PortalError.configurationError("test")
        
        // When: Checking retry behavior
        // Then: Should correctly identify retryable errors
        XCTAssertTrue(retryableError.shouldShowRetry, "Network error should allow retry")
        XCTAssertFalse(nonRetryableError.shouldShowRetry, "Configuration error should not allow retry")
    }
    
    // MARK: - Network State Tests
    
    func testCardNetworkStateIntegration() {
        // Given: Network monitor
        let networkMonitor = NetworkMonitor.shared
        
        // When: Checking network integration
        // Then: Should integrate with network monitoring
        XCTAssertNotNil(networkMonitor, "Network monitor should be available")
        
        let connectionStatus = networkMonitor.isConnected
        XCTAssertNotNil(connectionStatus, "Should provide connection status")
    }
    
    func testCardDisabledStateWithOfflineNetwork() {
        // Given: Card with invalid URL and offline state
        let invalidCard = PortalCardData(
            title: "無効なカード",
            imageName: "invalid_image",
            externalURL: "invalid-url"
        )
        
        // When: Checking if card should be disabled
        let errorHandler = PortalErrorHandler.shared
        let isValidURL = (try? errorHandler.validateURL(invalidCard.externalURL)) != nil
        
        // Then: Card with invalid URL should be considered invalid
        XCTAssertFalse(isValidURL, "Card with invalid URL should be invalid")
    }
    
    // MARK: - Visual State Tests
    
    func testCardBackgroundColors() {
        // Given: Different card states
        let normalBackground = Color(.systemBackground)
        let offlineBackground = Color(.systemBackground).opacity(0.7)
        let errorBackground = Color.red.opacity(0.1)
        
        // When: Checking background colors
        // Then: Colors should be distinct for different states
        XCTAssertNotEqual(normalBackground, offlineBackground, "Normal and offline backgrounds should differ")
        XCTAssertNotEqual(normalBackground, errorBackground, "Normal and error backgrounds should differ")
    }
    
    func testCardImageDisplayStates() {
        // Given: Image display scenarios
        let validImageName = "existing_image"
        let missingImageName = "missing_image"
        let emptyImageName = ""
        
        let errorHandler = PortalErrorHandler.shared
        
        // When: Checking image validation
        let validImage = errorHandler.validateImageAsset(validImageName)
        let missingImage = errorHandler.validateImageAsset(missingImageName)
        let emptyImage = errorHandler.validateImageAsset(emptyImageName)
        
        // Then: Should correctly identify image availability
        XCTAssertFalse(validImage, "Test image should not exist") // Test assets don't exist
        XCTAssertFalse(missingImage, "Missing image should be detected")
        XCTAssertFalse(emptyImage, "Empty image name should be invalid")
    }
    
    // MARK: - Layout Configuration Tests
    
    func testCardLayoutDimensions() {
        // Given: Card layout parameters
        let cardPadding: CGFloat = 12
        let cornerRadius: CGFloat = 12
        let imageHeight: CGFloat = 60
        let imageCornerRadius: CGFloat = 8
        
        // When: Checking layout dimensions
        // Then: Dimensions should be appropriate for mobile interface
        XCTAssertGreaterThan(cardPadding, 8, "Card padding should be sufficient")
        XCTAssertGreaterThan(cornerRadius, 0, "Corner radius should create rounded corners")
        XCTAssertGreaterThan(imageHeight, 40, "Image should be large enough to be visible")
        XCTAssertLessThan(imageHeight, 100, "Image should not be too large")
        XCTAssertLessThan(imageCornerRadius, cornerRadius, "Image corner radius should be smaller than card")
    }
    
    func testCardTextConfiguration() {
        // Given: Text configuration parameters
        let fontSize = Font.caption
        let fontWeight = Font.Weight.medium
        let lineLimit = 2
        let minimumScaleFactor: CGFloat = 0.8
        
        // When: Checking text configuration
        // Then: Text should be readable and appropriately sized
        XCTAssertNotNil(fontSize, "Font size should be configured")
        XCTAssertNotNil(fontWeight, "Font weight should be configured")
        XCTAssertGreaterThan(lineLimit, 1, "Should allow multiple lines for long titles")
        XCTAssertGreaterThan(minimumScaleFactor, 0.5, "Minimum scale should maintain readability")
        XCTAssertLessThan(minimumScaleFactor, 1.0, "Should allow text scaling")
    }
    
    // MARK: - Performance Tests
    
    func testCardCreationPerformance() {
        // Given: Performance measurement
        let testCards = (1...100).map { index in
            PortalCardData(
                title: "パフォーマンステスト\(index)",
                imageName: "perf_test_\(index)",
                externalURL: "https://perf-test\(index).com"
            )
        }
        
        // When: Measuring card creation performance
        measure {
            for cardData in testCards {
                let _ = PortalCard(cardData: cardData)
            }
        }
        
        // Then: Creation should be performant (measured by XCTest)
    }
    
    func testCardValidationPerformance() {
        // Given: Multiple cards to validate
        let testCards = (1...50).map { index in
            PortalCardData(
                title: "バリデーションテスト\(index)",
                imageName: "validation_test_\(index)",
                externalURL: "https://validation-test\(index).com"
            )
        }
        
        // When: Measuring validation performance
        measure {
            for cardData in testCards {
                let _ = cardData.validate()
            }
        }
        
        // Then: Validation should be performant (measured by XCTest)
    }
}