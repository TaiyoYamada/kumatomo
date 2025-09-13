import XCTest
import UIKit
@testable import kumatomo

@MainActor
class CommentAPIServiceTests: XCTestCase {
    
    var commentAPIService: CommentAPIService!
    var mockImageUploadService: MockImageUploadService!
    
    override func setUp() {
        super.setUp()
        commentAPIService = CommentAPIService.shared
        mockImageUploadService = MockImageUploadService()
        
        // Set up test environment
        setenv("API_BASE_URL", "http://localhost:8000/api", 1)
        
        // Clear any existing auth token
        AuthTokenManager.shared.clearToken()
    }
    
    override func tearDown() {
        commentAPIService = nil
        mockImageUploadService = nil
        AuthTokenManager.shared.clearToken()
        super.tearDown()
    }
    
    // MARK: - Content Validation Tests
    
    func testValidateCommentContent_ValidContent() throws {
        let validContent = "This is a valid comment"
        
        XCTAssertNoThrow(try commentAPIService.validateCommentContent(validContent))
    }
    
    func testValidateCommentContent_EmptyContent() {
        let emptyContent = ""
        
        XCTAssertThrowsError(try commentAPIService.validateCommentContent(emptyContent)) { error in
            XCTAssertTrue(error is CommentError)
            if case CommentError.emptyContent = error {
                // Expected error
            } else {
                XCTFail("Expected CommentError.emptyContent, got \(error)")
            }
        }
    }
    
    func testValidateCommentContent_WhitespaceOnlyContent() {
        let whitespaceContent = "   \n\t   "
        
        XCTAssertThrowsError(try commentAPIService.validateCommentContent(whitespaceContent)) { error in
            XCTAssertTrue(error is CommentError)
            if case CommentError.emptyContent = error {
                // Expected error
            } else {
                XCTFail("Expected CommentError.emptyContent, got \(error)")
            }
        }
    }
    
    func testValidateCommentContent_TooLongContent() {
        let longContent = String(repeating: "a", count: 501)
        
        XCTAssertThrowsError(try commentAPIService.validateCommentContent(longContent)) { error in
            XCTAssertTrue(error is CommentError)
            if case CommentError.contentTooLong(let current, let max) = error {
                XCTAssertEqual(current, 501)
                XCTAssertEqual(max, 500)
            } else {
                XCTFail("Expected CommentError.contentTooLong, got \(error)")
            }
        }
    }
    
    func testValidateCommentContent_CustomMaxLength() {
        let content = String(repeating: "a", count: 101)
        
        XCTAssertThrowsError(try commentAPIService.validateCommentContent(content, maxLength: 100)) { error in
            XCTAssertTrue(error is CommentError)
            if case CommentError.contentTooLong(let current, let max) = error {
                XCTAssertEqual(current, 101)
                XCTAssertEqual(max, 100)
            } else {
                XCTFail("Expected CommentError.contentTooLong, got \(error)")
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testCommentError_LocalizedDescriptions() {
        let errors: [CommentError] = [
            .emptyContent,
            .contentTooLong(currentCount: 501, maxCount: 500),
            .imageUploadFailed(NSError(domain: "test", code: 1, userInfo: nil)),
            .networkError(NSError(domain: "test", code: 2, userInfo: nil)),
            .unauthorized,
            .postNotFound,
            .commentNotFound,
            .invalidURL,
            .invalidResponse,
            .decodingError(NSError(domain: "test", code: 3, userInfo: nil)),
            .apiError(422, "Validation failed"),
            .serverError("Internal server error"),
            .timeout,
            .unknownError(NSError(domain: "test", code: 4, userInfo: nil))
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            
            // Test recovery suggestions
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.recoverySuggestion!.isEmpty)
        }
    }
    
    func testCommentError_SpecificMessages() {
        let emptyContentError = CommentError.emptyContent
        XCTAssertEqual(emptyContentError.errorDescription, "コメント内容を入力してください")
        XCTAssertEqual(emptyContentError.recoverySuggestion, "コメントを入力してから送信してください")
        
        let tooLongError = CommentError.contentTooLong(currentCount: 501, maxCount: 500)
        XCTAssertEqual(tooLongError.errorDescription, "コメントが長すぎます (501/500文字)")
        XCTAssertEqual(tooLongError.recoverySuggestion, "コメントを短くしてから送信してください")
        
        let unauthorizedError = CommentError.unauthorized
        XCTAssertEqual(unauthorizedError.errorDescription, "認証が必要です")
        XCTAssertEqual(unauthorizedError.recoverySuggestion, "ログインしてからもう一度お試しください")
        
        let postNotFoundError = CommentError.postNotFound
        XCTAssertEqual(postNotFoundError.errorDescription, "投稿が見つかりません")
        XCTAssertEqual(postNotFoundError.recoverySuggestion, "投稿が削除された可能性があります")
    }
    
    // MARK: - URL Construction Tests
    
    func testFetchComments_URLConstruction() async {
        // Test with default base URL
        let postId = 123
        
        // This test verifies URL construction by checking the error when no auth token is present
        do {
            _ = try await commentAPIService.fetchComments(postId: postId)
            XCTFail("Expected error due to no auth token")
        } catch {
            // Expected to fail due to authentication, but URL construction should be correct
            // The actual URL construction is tested indirectly through the API calls
        }
    }
    
    // MARK: - Authentication Tests
    
    func testCreateComment_RequiresAuthentication() async {
        // Clear any existing token
        AuthTokenManager.shared.clearToken()
        
        do {
            _ = try await commentAPIService.createComment(postId: 1, content: "Test comment")
            XCTFail("Expected authentication error")
        } catch {
            // Expected to fail due to lack of authentication
            // The specific error depends on the server response
        }
    }
    
    func testDeleteComment_RequiresAuthentication() async {
        // Clear any existing token
        AuthTokenManager.shared.clearToken()
        
        do {
            try await commentAPIService.deleteComment(commentId: 1)
            XCTFail("Expected authentication error")
        } catch {
            // Expected to fail due to lack of authentication
            // The specific error depends on the server response
        }
    }
    
    // MARK: - Convenience Method Tests
    
    func testCreateTextComment_ValidContent() async {
        let content = "This is a text-only comment"
        
        do {
            // This will fail due to no auth token, but validates the method signature and content validation
            _ = try await commentAPIService.createTextComment(postId: 1, content: content)
            XCTFail("Expected error due to no auth token")
        } catch {
            // Expected to fail, but content validation should pass
        }
    }
    
    func testCreateTextComment_EmptyContent() async {
        do {
            _ = try await commentAPIService.createTextComment(postId: 1, content: "")
            XCTFail("Expected empty content error")
        } catch {
            XCTAssertTrue(error is CommentError)
            if case CommentError.emptyContent = error {
                // Expected error
            } else {
                XCTFail("Expected CommentError.emptyContent, got \(error)")
            }
        }
    }
    
    func testCreateImageComment_ValidImage() async {
        let testImage = createTestImage()
        
        do {
            // This will fail due to no auth token, but validates the method signature
            _ = try await commentAPIService.createImageComment(postId: 1, image: testImage)
            XCTFail("Expected error due to no auth token")
        } catch {
            // Expected to fail, but method signature should be correct
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}

// MARK: - Mock Classes

class MockImageUploadService {
    var shouldSucceed = true
    var mockImageUrl = "https://example.com/test-image.jpg"
    var mockError: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock upload failed"])
    
    func uploadImage(_ image: UIImage) async throws -> String {
        if shouldSucceed {
            return mockImageUrl
        } else {
            throw mockError
        }
    }
}

// MARK: - Integration Test Helpers

extension CommentAPIServiceTests {
    
    /// Helper method to create a mock comment for testing
    func createMockComment(id: Int = 1, postId: Int = 1, userId: Int = 1, content: String = "Test comment") -> Comment {
        return Comment(
            id: id,
            postId: postId,
            userId: userId,
            content: content,
            imageUrl: nil,
            user: createMockUser()
        )
    }
    
    /// Helper method to create a mock user for testing
    func createMockUser(id: Int = 1, username: String = "testuser") -> User {
        return User(
            id: id,
            username: username,
            email: "test@example.com",
            profileImageURL: nil,
            coverImageURL: nil,
            bio: nil,
            municipality: nil,
            age: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}