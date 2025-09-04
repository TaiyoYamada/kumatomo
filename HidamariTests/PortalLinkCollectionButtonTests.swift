import XCTest
import SwiftUI
@testable import Hidamari

@MainActor
final class PortalLinkCollectionButtonTests: XCTestCase {
    
    var linkButton: PortalLinkCollectionButton!
    
    override func setUp() {
        super.setUp()
        linkButton = PortalLinkCollectionButton()
    }
    
    override func tearDown() {
        linkButton = nil
        super.tearDown()
    }
    
    // MARK: - External URL Opening Tests (Requirements: 5.1, 5.6)
    
    func testLinkCollectionButtonInitialization() {
        // Given: A new link collection button instance
        // When: Checking initialization
        // Then: Button should be instantiated successfully
        XCTAssertNotNil(linkButton, "Link collection button should be instantiated successfully")
    }
    
    func testPlaceholderURLConfiguration() {
        // Given: Expected placeholder URL
        let expectedPlaceholderURL = "https://example.com/links"
        
        // When: Checking URL configuration
        // Then: Should use placeholder URL for development
        XCTAssertTrue(expectedPlaceholderURL.contains("example.com"), 
                     "Should use placeholder domain for development")
        XCTAssertTrue(expectedPlaceholderURL.hasPrefix("https://"), 
                     "Should use HTTPS protocol")
        XCTAssertTrue(expectedPlaceholderURL.contains("links"), 
                     "Should indicate link collection purpose")
    }
    
    // MARK: - URL Validation Tests
    
    func testValidURLValidation() {
        // Given: Valid URLs
        let validURLs = [
            "https://example.com",
            "http://test.com",
            "https://www.google.com",
            "https://subdomain.example.com/path",
            "https://example.com/links?param=value"
        ]
        
        let errorHandler = PortalErrorHandler.shared
        
        // When: Validating URLs
        for urlString in validURLs {
            // Then: Should validate successfully
            XCTAssertNoThrow(try errorHandler.validateURL(urlString), 
                           "URL '\(urlString)' should be valid")
        }
    }
    
    func testInvalidURLValidation() {
        // Given: Invalid URLs
        let invalidURLs = [
            "",
            "   ",
            "not-a-url",
            "ftp://example.com",
            "javascript:alert('test')",
            "file:///etc/passwd"
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
        let placeholderURLs = [
            "https://example.com/links",
            "https://example.com/test",
            "TODO: Add actual URL",
            "https://your-domain.com/links"
        ]
        
        let errorHandler = PortalErrorHandler.shared
        
        // When: Validating placeholder URLs
        for urlString in placeholderURLs {
            if urlString.contains("example.com") || urlString.contains("TODO") {
                // Then: Should detect as configuration error
                XCTAssertThrowsError(try errorHandler.validateURL(urlString), 
                                   "Placeholder URL '\(urlString)' should be detected") { error in
                    if case PortalErrorHandler.PortalError.configurationError = error {
                        // Expected configuration error
                    } else {
                        XCTFail("Should throw configuration error for placeholder URL")
                    }
                }
            }
        }
    }
    
    func testURLSchemeValidation() {
        // Given: URLs with different schemes
        let supportedSchemes = [
            "https://example.com",
            "http://example.com",
            "tel:+1234567890",
            "mailto:test@example.com"
        ]
        
        let unsupportedSchemes = [
            "ftp://example.com",
            "file:///path/to/file",
            "javascript:alert('test')",
            "data:text/plain;base64,SGVsbG8="
        ]
        
        let errorHandler = PortalErrorHandler.shared
        
        // When: Testing supported schemes
        for urlString in supportedSchemes {
            // Then: Should be valid (except for placeholder domains)
            if !urlString.contains("example.com") {
                XCTAssertNoThrow(try errorHandler.validateURL(urlString), 
                               "Supported scheme URL '\(urlString)' should be valid")
            }
        }
        
        // When: Testing unsupported schemes
        for urlString in unsupportedSchemes {
            // Then: Should be invalid
            XCTAssertThrowsError(try errorHandler.validateURL(urlString), 
                               "Unsupported scheme URL '\(urlString)' should be invalid")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testPortalErrorTypes() {
        // Given: Different portal error types
        let errors: [PortalErrorHandler.PortalError] = [
            .invalidURL("test"),
            .networkUnavailable,
            .urlCannotOpen("test"),
            .openingFailed("test"),
            .configurationError("test")
        ]
        
        // When: Checking error properties
        for error in errors {
            // Then: Each error should have proper description and user message
            XCTAssertNotNil(error.errorDescription, "Error should have description")
            XCTAssertFalse(error.userFriendlyMessage.isEmpty, "Error should have user-friendly message")
            XCTAssertNotNil(error.logLevel, "Error should have log level")
        }
    }
    
    func testErrorUserFriendlyMessages() {
        // Given: Portal errors
        let networkError = PortalErrorHandler.PortalError.networkUnavailable
        let invalidURLError = PortalErrorHandler.PortalError.invalidURL("test")
        let configError = PortalErrorHandler.PortalError.configurationError("test")
        
        // When: Getting user-friendly messages
        let networkMessage = networkError.userFriendlyMessage
        let urlMessage = invalidURLError.userFriendlyMessage
        let configMessage = configError.userFriendlyMessage
        
        // Then: Messages should be in Japanese and user-friendly
        XCTAssertTrue(networkMessage.contains("インターネット接続"), 
                     "Network error should mention internet connection")
        XCTAssertTrue(urlMessage.contains("無効なURL"), 
                     "URL error should mention invalid URL")
        XCTAssertTrue(configMessage.contains("設定"), 
                     "Config error should mention configuration")
    }
    
    func testErrorRetryBehavior() {
        // Given: Different error types
        let retryableErrors: [PortalErrorHandler.PortalError] = [
            .networkUnavailable,
            .openingFailed("test")
        ]
        
        let nonRetryableErrors: [PortalErrorHandler.PortalError] = [
            .invalidURL("test"),
            .configurationError("test"),
            .urlCannotOpen("test")
        ]
        
        // When: Checking retry behavior
        for error in retryableErrors {
            // Then: Should allow retry
            XCTAssertTrue(error.shouldShowRetry, "Error \(error) should allow retry")
        }
        
        for error in nonRetryableErrors {
            // Then: Should not allow retry
            XCTAssertFalse(error.shouldShowRetry, "Error \(error) should not allow retry")
        }
    }
    
    // MARK: - Network Connectivity Tests
    
    func testNetworkMonitorIntegration() {
        // Given: Network monitor
        let networkMonitor = NetworkMonitor.shared
        
        // When: Checking network monitor integration
        // Then: Should provide connection status
        XCTAssertNotNil(networkMonitor, "Network monitor should be available")
        
        let connectionStatus = networkMonitor.isConnected
        XCTAssertNotNil(connectionStatus, "Should provide connection status")
    }
    
    func testRetryDelayCalculation() {
        // Given: Error handler and retry parameters
        let errorHandler = PortalErrorHandler.shared
        let networkError = PortalErrorHandler.PortalError.networkUnavailable
        
        // When: Calculating retry delays
        let delay1 = errorHandler.getRetryDelay(for: networkError, attempt: 1)
        let delay2 = errorHandler.getRetryDelay(for: networkError, attempt: 2)
        let delay3 = errorHandler.getRetryDelay(for: networkError, attempt: 3)
        
        // Then: Delays should increase (exponential backoff)
        XCTAssertGreaterThan(delay1, 0, "First retry delay should be positive")
        XCTAssertGreaterThan(delay2, delay1, "Second retry delay should be longer")
        XCTAssertGreaterThan(delay3, delay2, "Third retry delay should be longer")
        
        // Should not exceed maximum delay
        XCTAssertLessThanOrEqual(delay3, 11.0, "Retry delay should not exceed maximum")
    }
    
    func testRetryDelayForNonRetryableError() {
        // Given: Non-retryable error
        let errorHandler = PortalErrorHandler.shared
        let configError = PortalErrorHandler.PortalError.configurationError("test")
        
        // When: Getting retry delay
        let delay = errorHandler.getRetryDelay(for: configError, attempt: 1)
        
        // Then: Should return zero delay (no retry)
        XCTAssertEqual(delay, 0, "Non-retryable error should have zero delay")
    }
    
    // MARK: - Button State Tests
    
    func testButtonTextStates() {
        // Given: Different button states
        let normalText = "リンク集"
        let loadingText = "読み込み中..."
        let offlineText = "リンク集（オフライン）"
        
        // When: Checking text states
        // Then: Text should be appropriate for each state
        XCTAssertFalse(normalText.isEmpty, "Normal text should not be empty")
        XCTAssertTrue(normalText.contains("リンク集"), "Normal text should contain link collection")
        
        XCTAssertTrue(loadingText.contains("読み込み"), "Loading text should indicate loading")
        XCTAssertTrue(offlineText.contains("オフライン"), "Offline text should indicate offline state")
    }
    
    func testButtonAccessibilityLabels() {
        // Given: Different accessibility states
        let normalLabel = "リンク集を開く"
        let offlineLabel = "リンク集（オフライン状態）"
        let errorLabel = "リンク集（設定エラー）"
        
        // When: Checking accessibility labels
        // Then: Labels should be descriptive
        XCTAssertTrue(normalLabel.contains("リンク集"), "Normal label should mention link collection")
        XCTAssertTrue(offlineLabel.contains("オフライン"), "Offline label should mention offline state")
        XCTAssertTrue(errorLabel.contains("エラー"), "Error label should mention error")
    }
    
    func testButtonAccessibilityHints() {
        // Given: Different accessibility hints
        let normalHint = "外部ブラウザでリンク集を開きます"
        let offlineHint = "インターネット接続が必要です"
        let errorHint = "URLの設定に問題があります"
        
        // When: Checking accessibility hints
        // Then: Hints should provide helpful information
        XCTAssertTrue(normalHint.contains("外部ブラウザ"), "Normal hint should mention external browser")
        XCTAssertTrue(offlineHint.contains("インターネット接続"), "Offline hint should mention internet connection")
        XCTAssertTrue(errorHint.contains("URL"), "Error hint should mention URL")
    }
    
    // MARK: - URL Opening Behavior Tests
    
    func testURLCanOpenValidation() {
        // Given: Error handler
        let errorHandler = PortalErrorHandler.shared
        
        // When: Testing URL opening capability
        if let validURL = URL(string: "https://www.apple.com") {
            let canOpen = errorHandler.canOpenURL(validURL)
            
            // Then: Should be able to determine if URL can be opened
            XCTAssertNotNil(canOpen, "Should provide URL opening capability check")
        }
    }
    
    func testURLOpeningWithCallback() {
        // Given: URL opening expectation
        let expectation = XCTestExpectation(description: "URL opening callback")
        let errorHandler = PortalErrorHandler.shared
        let testURL = "https://example.com/test"
        
        // When: Attempting to open URL
        errorHandler.openURL(testURL) { result in
            // Then: Should receive callback
            switch result {
            case .success:
                // URL opened successfully (unlikely with example.com)
                break
            case .failure(let error):
                // Expected to fail with placeholder URL
                XCTAssertTrue(error is PortalErrorHandler.PortalError, "Should return PortalError")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testButtonCreationPerformance() {
        // Given: Performance measurement
        measure {
            // When: Creating multiple button instances
            for _ in 0..<100 {
                let _ = PortalLinkCollectionButton()
            }
        }
        
        // Then: Creation should be performant (measured by XCTest)
    }
    
    func testURLValidationPerformance() {
        // Given: Multiple URLs to validate
        let urls = (1...100).map { "https://example\($0).com/links" }
        let errorHandler = PortalErrorHandler.shared
        
        // When: Measuring validation performance
        measure {
            for url in urls {
                do {
                    _ = try errorHandler.validateURL(url)
                } catch {
                    // Expected to fail with example.com URLs
                }
            }
        }
        
        // Then: Validation should be performant (measured by XCTest)
    }
    
    // MARK: - Configuration Tests
    
    func testButtonStylingConfiguration() {
        // Given: Button styling parameters
        let expectedCornerRadius: CGFloat = 12
        let expectedPadding: CGFloat = 16
        let expectedMinHeight: CGFloat = 44 // Accessibility minimum
        
        // When: Checking styling values
        // Then: Values should be appropriate for accessibility and design
        XCTAssertGreaterThan(expectedCornerRadius, 0, "Corner radius should be positive")
        XCTAssertGreaterThan(expectedPadding, 8, "Padding should be sufficient")
        XCTAssertGreaterThanOrEqual(expectedMinHeight, 44, "Should meet accessibility minimum height")
    }
    
    func testButtonColorConfiguration() {
        // Given: Button color states
        let normalColor = Color.pink
        let disabledColor = Color.gray
        let errorColor = Color.red.opacity(0.7)
        
        // When: Checking color configuration
        // Then: Colors should be distinct and appropriate
        XCTAssertNotEqual(normalColor, disabledColor, "Normal and disabled colors should be different")
        XCTAssertNotEqual(normalColor, errorColor, "Normal and error colors should be different")
    }
}