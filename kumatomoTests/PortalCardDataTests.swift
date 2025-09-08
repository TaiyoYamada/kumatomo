import XCTest
import SwiftUI
@testable import kumatomo

@MainActor
final class PortalCardDataTests: XCTestCase {
    
    // MARK: - Model Validation Tests (Requirements: 5.1, 5.6)
    
    func testPortalCardDataInitialization() {
        // Given: Valid card data parameters
        let title = "テストサービス"
        let imageName = "test_image"
        let externalURL = "https://example.com/test"
        
        // When: Creating a PortalCardData instance
        let cardData = PortalCardData(
            title: title,
            imageName: imageName,
            externalURL: externalURL
        )
        
        // Then: All properties should be set correctly
        XCTAssertEqual(cardData.title, title, "Title should match input")
        XCTAssertEqual(cardData.imageName, imageName, "Image name should match input")
        XCTAssertEqual(cardData.externalURL, externalURL, "External URL should match input")
        XCTAssertNotNil(cardData.id, "ID should be automatically generated")
    }
    
    func testPortalCardDataIdentifiable() {
        // Given: Two PortalCardData instances
        let cardData1 = PortalCardData(
            title: "サービス1",
            imageName: "image1",
            externalURL: "https://example.com/1"
        )
        let cardData2 = PortalCardData(
            title: "サービス2",
            imageName: "image2",
            externalURL: "https://example.com/2"
        )
        
        // When: Comparing their IDs
        // Then: Each card should have a unique ID
        XCTAssertNotEqual(cardData1.id, cardData2.id, "Each card should have a unique ID")
    }
    
    func testPortalCardDataWithEmptyValues() {
        // Given: Empty string values
        let cardData = PortalCardData(
            title: "",
            imageName: "",
            externalURL: ""
        )
        
        // When: Accessing properties
        // Then: Empty values should be preserved
        XCTAssertEqual(cardData.title, "", "Empty title should be preserved")
        XCTAssertEqual(cardData.imageName, "", "Empty image name should be preserved")
        XCTAssertEqual(cardData.externalURL, "", "Empty URL should be preserved")
        XCTAssertNotNil(cardData.id, "ID should still be generated for empty data")
    }
    
    func testPortalCardDataWithJapaneseText() {
        // Given: Japanese text for title
        let japaneseTitle = "日本語サービス名前テスト"
        let cardData = PortalCardData(
            title: japaneseTitle,
            imageName: "japanese_service",
            externalURL: "https://example.com/japanese"
        )
        
        // When: Accessing the title
        // Then: Japanese text should be preserved correctly
        XCTAssertEqual(cardData.title, japaneseTitle, "Japanese text should be preserved")
        XCTAssertTrue(cardData.title.contains("日本語"), "Japanese characters should be intact")
    }
    
    func testPortalCardDataWithLongTitle() {
        // Given: A very long title
        let longTitle = "これは非常に長いサービス名前でテストのために作成されたものです。実際のアプリケーションでは適切な長さに制限されるべきです。"
        let cardData = PortalCardData(
            title: longTitle,
            imageName: "long_title_service",
            externalURL: "https://example.com/long"
        )
        
        // When: Accessing the title
        // Then: Long title should be preserved
        XCTAssertEqual(cardData.title, longTitle, "Long title should be preserved")
        XCTAssertGreaterThan(cardData.title.count, 50, "Title should be longer than 50 characters")
    }
    
    // MARK: - Sample Data Validation Tests
    
    func testSamplePortalCardsCount() {
        // Given: Sample portal cards data
        // When: Checking the count
        // Then: Should have exactly 6 cards for 3x2 grid
        XCTAssertEqual(samplePortalCards.count, 6, "Sample data should contain exactly 6 cards")
    }
    
    func testSamplePortalCardsStructure() {
        // Given: Sample portal cards data
        // When: Validating each card
        for (index, card) in samplePortalCards.enumerated() {
            // Then: Each card should have valid structure
            XCTAssertFalse(card.title.isEmpty, "Card \(index + 1) should have a non-empty title")
            XCTAssertFalse(card.imageName.isEmpty, "Card \(index + 1) should have a non-empty image name")
            XCTAssertFalse(card.externalURL.isEmpty, "Card \(index + 1) should have a non-empty URL")
            XCTAssertNotNil(card.id, "Card \(index + 1) should have a valid ID")
        }
    }
    
    func testSamplePortalCardsImageNaming() {
        // Given: Sample portal cards data
        // When: Checking image naming convention
        for (index, card) in samplePortalCards.enumerated() {
            let expectedImageName = "portal_card_\(index + 1)"
            
            // Then: Image names should follow the convention
            XCTAssertEqual(card.imageName, expectedImageName, 
                          "Card \(index + 1) should have image name '\(expectedImageName)'")
        }
    }
    
    func testSamplePortalCardsURLFormat() {
        // Given: Sample portal cards data
        // When: Checking URL format
        for (index, card) in samplePortalCards.enumerated() {
            // Then: URLs should be in expected format (placeholder URLs for development)
            XCTAssertTrue(card.externalURL.hasPrefix("https://"), 
                         "Card \(index + 1) URL should use HTTPS")
            XCTAssertTrue(card.externalURL.contains("example.com"), 
                         "Card \(index + 1) should use placeholder domain")
            XCTAssertTrue(card.externalURL.contains("service\(index + 1)"), 
                         "Card \(index + 1) should have service-specific path")
        }
    }
    
    func testSamplePortalCardsTitles() {
        // Given: Sample portal cards data
        // When: Checking titles
        for (index, card) in samplePortalCards.enumerated() {
            let expectedTitle = "サービス\(index + 1)"
            
            // Then: Titles should follow the expected pattern
            XCTAssertEqual(card.title, expectedTitle, 
                          "Card \(index + 1) should have title '\(expectedTitle)'")
            XCTAssertTrue(card.title.contains("サービス"), 
                         "Card \(index + 1) title should contain Japanese text")
        }
    }
    
    // MARK: - Slideshow Data Validation Tests
    
    func testPortalSlideshowImagesCount() {
        // Given: Portal slideshow images data
        // When: Checking the count
        // Then: Should have exactly 5 slideshow images
        XCTAssertEqual(portalSlideshowImages.count, 5, "Should have exactly 5 slideshow images")
    }
    
    func testPortalSlideshowImagesNaming() {
        // Given: Portal slideshow images data
        // When: Checking naming convention
        for (index, imageName) in portalSlideshowImages.enumerated() {
            let expectedImageName = "portal_slide_\(index + 1)"
            
            // Then: Image names should follow the convention
            XCTAssertEqual(imageName, expectedImageName, 
                          "Slideshow image \(index + 1) should be named '\(expectedImageName)'")
        }
    }
    
    func testPortalSlideshowImagesNotEmpty() {
        // Given: Portal slideshow images data
        // When: Checking each image name
        for (index, imageName) in portalSlideshowImages.enumerated() {
            // Then: No image name should be empty
            XCTAssertFalse(imageName.isEmpty, "Slideshow image \(index + 1) name should not be empty")
        }
    }
    
    // MARK: - Card Validation Extension Tests
    
    func testPortalCardDataValidationExtension() {
        // Given: A card with placeholder data
        let cardWithPlaceholder = PortalCardData(
            title: "テストサービス",
            imageName: "nonexistent_image",
            externalURL: "https://example.com/test"
        )
        
        // When: Validating the card
        let errors = cardWithPlaceholder.validate()
        
        // Then: Should detect configuration issues
        XCTAssertFalse(errors.isEmpty, "Card with placeholder data should have validation errors")
        
        // Check for specific error types
        let hasAssetError = errors.contains { error in
            if case .assetNotFound = error { return true }
            return false
        }
        let hasConfigError = errors.contains { error in
            if case .configurationError = error { return true }
            return false
        }
        
        XCTAssertTrue(hasAssetError || hasConfigError, "Should detect asset or configuration errors")
    }
    
    func testPortalCardDataIsValidProperty() {
        // Given: A card with invalid configuration
        let invalidCard = PortalCardData(
            title: "無効なカード",
            imageName: "missing_image",
            externalURL: "invalid-url"
        )
        
        // When: Checking if card is valid
        let isValid = invalidCard.isValid
        
        // Then: Should return false for invalid configuration
        XCTAssertFalse(isValid, "Card with invalid configuration should not be valid")
    }
    
    // MARK: - Performance Tests
    
    func testPortalCardDataCreationPerformance() {
        // Given: Performance measurement
        measure {
            // When: Creating multiple card instances
            for i in 0..<1000 {
                let _ = PortalCardData(
                    title: "パフォーマンステスト\(i)",
                    imageName: "test_image_\(i)",
                    externalURL: "https://example.com/test\(i)"
                )
            }
        }
        
        // Then: Creation should be performant (measured by XCTest)
    }
    
    func testSampleDataAccessPerformance() {
        // Given: Performance measurement
        measure {
            // When: Accessing sample data multiple times
            for _ in 0..<1000 {
                let _ = samplePortalCards.count
                let _ = portalSlideshowImages.count
                let _ = samplePortalCards.first?.title
                let _ = portalSlideshowImages.first
            }
        }
        
        // Then: Access should be performant (measured by XCTest)
    }
}