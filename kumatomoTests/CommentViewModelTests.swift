import XCTest
import UIKit
@testable import kumatomo

@MainActor
class CommentViewModelTests: XCTestCase {
    
    var viewModel: CommentViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = CommentViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.commentText, "")
        XCTAssertNil(viewModel.selectedImage)
        XCTAssertFalse(viewModel.isSubmitting)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showSuccessMessage)
        XCTAssertEqual(viewModel.successMessage, "")
        XCTAssertFalse(viewModel.showImagePicker)
        XCTAssertFalse(viewModel.isValidating)
        XCTAssertNil(viewModel.validationError)
    }
    
    // MARK: - Computed Properties Tests
    
    func testCanSubmit_WithValidText() {
        viewModel.commentText = "Valid comment"
        viewModel.validateContent()
        
        XCTAssertTrue(viewModel.canSubmit)
    }
    
    func testCanSubmit_WithEmptyText() {
        viewModel.commentText = ""
        viewModel.validateContent()
        
        XCTAssertFalse(viewModel.canSubmit)
    }
    
    func testCanSubmit_WithWhitespaceOnly() {
        viewModel.commentText = "   \n\t   "
        viewModel.validateContent()
        
        XCTAssertFalse(viewModel.canSubmit)
    }
    
    func testCanSubmit_WithImage() {
        let image = createTestImage()
        viewModel.setSelectedImage(image)
        
        XCTAssertTrue(viewModel.canSubmit)
    }
    
    func testCanSubmit_WhileSubmitting() {
        viewModel.commentText = "Valid comment"
        viewModel.isSubmitting = true
        
        XCTAssertFalse(viewModel.canSubmit)
    }
    
    func testCanSubmit_WithValidationError() {
        viewModel.commentText = String(repeating: "a", count: 600) // Over limit
        viewModel.validateContent()
        
        XCTAssertFalse(viewModel.canSubmit)
    }
    
    func testCharacterCount() {
        viewModel.commentText = "Hello"
        XCTAssertEqual(viewModel.characterCount, 5)
        
        viewModel.commentText = ""
        XCTAssertEqual(viewModel.characterCount, 0)
        
        viewModel.commentText = "こんにちは"
        XCTAssertEqual(viewModel.characterCount, 5)
    }
    
    func testIsOverCharacterLimit() {
        viewModel.commentText = String(repeating: "a", count: 500)
        XCTAssertFalse(viewModel.isOverCharacterLimit)
        
        viewModel.commentText = String(repeating: "a", count: 501)
        XCTAssertTrue(viewModel.isOverCharacterLimit)
    }
    
    func testRemainingCharacterCount() {
        viewModel.commentText = "Hello"
        XCTAssertEqual(viewModel.remainingCharacterCount, 495)
        
        viewModel.commentText = String(repeating: "a", count: 500)
        XCTAssertEqual(viewModel.remainingCharacterCount, 0)
        
        viewModel.commentText = String(repeating: "a", count: 501)
        XCTAssertEqual(viewModel.remainingCharacterCount, -1)
    }
    
    func testCharacterCountText() {
        // Should be empty when plenty of characters remain
        viewModel.commentText = "Hello"
        XCTAssertEqual(viewModel.characterCountText, "")
        
        // Should show count when approaching limit
        viewModel.commentText = String(repeating: "a", count: 460)
        XCTAssertEqual(viewModel.characterCountText, "40")
        
        // Should show negative count when over limit
        viewModel.commentText = String(repeating: "a", count: 501)
        XCTAssertEqual(viewModel.characterCountText, "-1")
    }
    
    func testCharacterCountColor() {
        // Normal state - should be secondary
        viewModel.commentText = "Hello"
        XCTAssertEqual(viewModel.characterCountColor, .secondary)
        
        // Warning state (21-50 remaining) - should be yellow
        viewModel.commentText = String(repeating: "a", count: 470)
        XCTAssertEqual(viewModel.characterCountColor, .yellow)
        
        // Critical state (1-20 remaining) - should be orange
        viewModel.commentText = String(repeating: "a", count: 490)
        XCTAssertEqual(viewModel.characterCountColor, .orange)
        
        // Over limit - should be red
        viewModel.commentText = String(repeating: "a", count: 501)
        XCTAssertEqual(viewModel.characterCountColor, .red)
    }
    
    func testHasContent() {
        // Empty state
        XCTAssertFalse(viewModel.hasContent)
        
        // With text
        viewModel.commentText = "Hello"
        XCTAssertTrue(viewModel.hasContent)
        
        // With whitespace only
        viewModel.commentText = "   "
        XCTAssertFalse(viewModel.hasContent)
        
        // With image only
        viewModel.commentText = ""
        viewModel.selectedImage = createTestImage()
        XCTAssertTrue(viewModel.hasContent)
    }
    
    // MARK: - Validation Tests
    
    func testValidateContent_EmptyContent() {
        viewModel.commentText = ""
        viewModel.selectedImage = nil
        viewModel.validateContent()
        
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertTrue(viewModel.validationError!.contains("コメント内容を入力するか、画像を選択してください"))
    }
    
    func testValidateContent_ValidText() {
        viewModel.commentText = "Valid comment"
        viewModel.validateContent()
        
        XCTAssertNil(viewModel.validationError)
    }
    
    func testValidateContent_TextTooLong() {
        viewModel.commentText = String(repeating: "a", count: 501)
        viewModel.validateContent()
        
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertTrue(viewModel.validationError!.contains("コメントが長すぎます"))
    }
    
    func testValidateContent_WithValidImage() {
        let image = createTestImage()
        viewModel.selectedImage = image
        viewModel.validateContent()
        
        XCTAssertNil(viewModel.validationError)
    }
    
    func testValidateForSubmission_ValidContent() {
        viewModel.commentText = "Valid comment"
        
        let result = viewModel.validateForSubmission()
        
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateForSubmission_EmptyContent() {
        viewModel.commentText = ""
        viewModel.selectedImage = nil
        
        let result = viewModel.validateForSubmission()
        
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateForSubmission_ContentTooLong() {
        viewModel.commentText = String(repeating: "a", count: 501)
        
        let result = viewModel.validateForSubmission()
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage!.contains("コメントが長すぎます"))
    }
    
    // MARK: - Form Management Tests
    
    func testClearForm() {
        // Set up some state
        viewModel.commentText = "Some text"
        viewModel.selectedImage = createTestImage()
        viewModel.errorMessage = "Some error"
        viewModel.validationError = "Some validation error"
        viewModel.showSuccessMessage = true
        viewModel.successMessage = "Success"
        
        // Clear form
        viewModel.clearForm()
        
        // Verify all state is cleared
        XCTAssertEqual(viewModel.commentText, "")
        XCTAssertNil(viewModel.selectedImage)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.validationError)
        XCTAssertFalse(viewModel.showSuccessMessage)
        XCTAssertEqual(viewModel.successMessage, "")
    }
    
    func testSetCommentText() {
        let testText = "Test comment"
        viewModel.setCommentText(testText)
        
        XCTAssertEqual(viewModel.commentText, testText)
        // Should trigger validation
        XCTAssertNil(viewModel.validationError)
    }
    
    func testSetSelectedImage() {
        let image = createTestImage()
        viewModel.setSelectedImage(image)
        
        XCTAssertEqual(viewModel.selectedImage, image)
        // Should trigger validation
        XCTAssertNil(viewModel.validationError)
    }
    
    func testRemoveSelectedImage() {
        let image = createTestImage()
        viewModel.selectedImage = image
        
        viewModel.removeSelectedImage()
        
        XCTAssertNil(viewModel.selectedImage)
    }
    
    func testProcessSelectedImage() {
        let image = createTestImage()
        viewModel.processSelectedImage(image)
        
        XCTAssertNotNil(viewModel.selectedImage)
        // Should trigger validation
        XCTAssertNil(viewModel.validationError)
    }
    
    // MARK: - Character Count Management Tests
    
    func testHandleTextChange() {
        let newText = "New comment text"
        viewModel.handleTextChange(newText)
        
        XCTAssertEqual(viewModel.commentText, newText)
        // Should trigger validation
        XCTAssertNil(viewModel.validationError)
    }
    
    func testHandleTextChange_OverLimit() {
        let longText = String(repeating: "a", count: 501)
        viewModel.handleTextChange(longText)
        
        XCTAssertEqual(viewModel.commentText, longText)
        // Should show validation error
        XCTAssertNotNil(viewModel.validationError)
    }
    
    func testGetFormattedCharacterCount() {
        // Normal state - should be empty
        viewModel.commentText = "Hello"
        XCTAssertEqual(viewModel.getFormattedCharacterCount(), "")
        
        // Approaching limit - should show count
        viewModel.commentText = String(repeating: "a", count: 460)
        XCTAssertEqual(viewModel.getFormattedCharacterCount(), "460/500")
        
        // Over limit - should show count
        viewModel.commentText = String(repeating: "a", count: 501)
        XCTAssertEqual(viewModel.getFormattedCharacterCount(), "501/500")
    }
    
    // MARK: - Utility Tests
    
    func testReset() {
        // Set up some state
        viewModel.commentText = "Some text"
        viewModel.selectedImage = createTestImage()
        viewModel.isSubmitting = true
        viewModel.errorMessage = "Some error"
        viewModel.showSuccessMessage = true
        viewModel.successMessage = "Success"
        viewModel.showImagePicker = true
        viewModel.isValidating = true
        viewModel.validationError = "Validation error"
        
        // Reset
        viewModel.reset()
        
        // Verify all state is reset
        XCTAssertEqual(viewModel.commentText, "")
        XCTAssertNil(viewModel.selectedImage)
        XCTAssertFalse(viewModel.isSubmitting)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showSuccessMessage)
        XCTAssertEqual(viewModel.successMessage, "")
        XCTAssertFalse(viewModel.showImagePicker)
        XCTAssertFalse(viewModel.isValidating)
        XCTAssertNil(viewModel.validationError)
    }
    
    func testFormStateSummary() {
        // Empty form
        XCTAssertEqual(viewModel.formStateSummary, "空のフォーム")
        
        // With text
        viewModel.commentText = "Hello"
        XCTAssertTrue(viewModel.formStateSummary.contains("テキスト: 5文字"))
        
        // With image
        viewModel.selectedImage = createTestImage()
        XCTAssertTrue(viewModel.formStateSummary.contains("画像: あり"))
        
        // While submitting
        viewModel.isSubmitting = true
        XCTAssertTrue(viewModel.formStateSummary.contains("送信中"))
        
        // With validation error
        viewModel.isSubmitting = false
        viewModel.validationError = "Test error"
        XCTAssertTrue(viewModel.formStateSummary.contains("エラー: Test error"))
    }
    
    // MARK: - Validation Status Tests
    
    func testValidationStatus_Empty() {
        XCTAssertEqual(viewModel.validationStatus, .empty)
    }
    
    func testValidationStatus_Validating() {
        viewModel.isValidating = true
        XCTAssertEqual(viewModel.validationStatus, .validating)
    }
    
    func testValidationStatus_Invalid() {
        viewModel.validationError = "Some error"
        XCTAssertEqual(viewModel.validationStatus, .invalid)
    }
    
    func testValidationStatus_Valid() {
        viewModel.commentText = "Valid comment"
        XCTAssertEqual(viewModel.validationStatus, .valid)
    }
    
    // MARK: - Mock Tests
    
    func testMockCreation() {
        let mockViewModel = CommentViewModel.mock()
        XCTAssertFalse(mockViewModel.commentText.isEmpty)
    }
    
    func testMockWithErrorCreation() {
        let mockViewModel = CommentViewModel.mockWithError()
        XCTAssertTrue(mockViewModel.isOverCharacterLimit)
        XCTAssertNotNil(mockViewModel.validationError)
    }
    
    func testMockSubmittingCreation() {
        let mockViewModel = CommentViewModel.mockSubmitting()
        XCTAssertTrue(mockViewModel.isSubmitting)
        XCTAssertFalse(mockViewModel.commentText.isEmpty)
    }
    
    // MARK: - Edge Cases Tests
    
    func testValidation_WithOnlyWhitespace() {
        viewModel.commentText = "   \n\t   "
        viewModel.validateContent()
        
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertFalse(viewModel.canSubmit)
    }
    
    func testValidation_ExactlyAtLimit() {
        viewModel.commentText = String(repeating: "a", count: 500)
        viewModel.validateContent()
        
        XCTAssertNil(viewModel.validationError)
        XCTAssertTrue(viewModel.canSubmit)
    }
    
    func testValidation_JustOverLimit() {
        viewModel.commentText = String(repeating: "a", count: 501)
        viewModel.validateContent()
        
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertFalse(viewModel.canSubmit)
    }
    
    func testCharacterCountDisplay_EdgeCases() {
        // At exactly 50 remaining
        viewModel.commentText = String(repeating: "a", count: 450)
        XCTAssertEqual(viewModel.characterCountText, "50")
        XCTAssertEqual(viewModel.characterCountColor, .yellow)
        
        // At exactly 20 remaining
        viewModel.commentText = String(repeating: "a", count: 480)
        XCTAssertEqual(viewModel.characterCountText, "20")
        XCTAssertEqual(viewModel.characterCountColor, .orange)
        
        // At exactly 0 remaining
        viewModel.commentText = String(repeating: "a", count: 500)
        XCTAssertEqual(viewModel.characterCountText, "0")
        XCTAssertEqual(viewModel.characterCountColor, .orange)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    private func createLargeTestImage() -> UIImage {
        return createTestImage(size: CGSize(width: 3000, height: 3000))
    }
}

// MARK: - Async Tests

extension CommentViewModelTests {
    
    func testSubmitComment_Success() async {
        // This test would require mocking the CommentAPIService
        // For now, we'll test the validation logic that happens before API call
        
        viewModel.commentText = "Valid comment"
        
        // Verify validation passes
        let validation = viewModel.validateForSubmission()
        XCTAssertTrue(validation.isValid)
        XCTAssertNil(validation.errorMessage)
    }
    
    func testSubmitComment_ValidationFailure() async {
        viewModel.commentText = "" // Empty content
        
        // Verify validation fails
        let validation = viewModel.validateForSubmission()
        XCTAssertFalse(validation.isValid)
        XCTAssertNotNil(validation.errorMessage)
    }
    
    func testSubmitComment_PreventMultipleSubmissions() async {
        viewModel.commentText = "Valid comment"
        viewModel.isSubmitting = true
        
        // Should not be able to submit while already submitting
        XCTAssertFalse(viewModel.canSubmit)
    }
}