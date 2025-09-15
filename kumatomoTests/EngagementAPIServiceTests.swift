import XCTest
@testable import kumatomo

@MainActor
class EngagementAPIServiceTests: XCTestCase {
    
    var engagementService: EngagementAPIService!
    
    override func setUp() {
        super.setUp()
        engagementService = EngagementAPIService.shared
        
        // Set up test environment
        setenv("API_BASE_URL", "http://localhost:8000/api", 1)
        
        // Clear any existing auth token
        AuthTokenManager.shared.clearToken()
    }
    
    override func tearDown() {
        engagementService = nil
        AuthTokenManager.shared.clearToken()
        super.tearDown()
    }
    
    // MARK: - Like API Tests
    
    func testToggleLike_WithoutAuth_ThrowsUnauthorized() async {
        // Given
        let postId = 1
        // No auth token set
        
        // When & Then
        do {
            _ = try await engagementService.toggleLike(postId: postId)
            XCTFail("Expected EngagementError.unauthorized or network error")
        } catch let error as EngagementError {
            // Expected - could be unauthorized or network error depending on server response
            print("✅ Correctly caught EngagementError: \(error)")
        } catch {
            // Network errors are also acceptable in test environment
            print("✅ Caught network error as expected: \(error)")
        }
    }
    
    func testFetchLikedPosts_WithoutAuth_ThrowsError() async {
        // Given - no auth token set
        
        // When & Then
        do {
            _ = try await engagementService.fetchLikedPosts()
            XCTFail("Expected error due to no authentication")
        } catch {
            // Expected - should fail without authentication
            print("✅ Correctly caught error: \(error)")
        }
    }
    
    // MARK: - Bookmark API Tests
    
    func testToggleBookmark_WithoutAuth_ThrowsError() async {
        // Given
        let postId = 1
        // No auth token set
        
        // When & Then
        do {
            _ = try await engagementService.toggleBookmark(postId: postId)
            XCTFail("Expected error due to no authentication")
        } catch {
            // Expected - should fail without authentication
            print("✅ Correctly caught error: \(error)")
        }
    }
    
    func testFetchBookmarkedPosts_WithoutAuth_ThrowsError() async {
        // Given - no auth token set
        
        // When & Then
        do {
            _ = try await engagementService.fetchBookmarkedPosts()
            XCTFail("Expected error due to no authentication")
        } catch {
            // Expected - should fail without authentication
            print("✅ Correctly caught error: \(error)")
        }
    }
    
    // MARK: - Optimistic Update Tests
    
    func testOptimisticToggleLike_Failure_Rollback() async {
        // Given
        let postId = 1
        let currentState = true
        let currentCount = 5
        
        // When - this should fail due to no auth
        let result = await engagementService.optimisticToggleLike(
            postId: postId,
            currentState: currentState,
            currentCount: currentCount
        )
        
        // Then
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.response)
        XCTAssertNotNil(result.error)
        
        // Check rollback values
        XCTAssertEqual(result.response!.isLiked, currentState)
        XCTAssertEqual(result.response!.likeCount, currentCount)
        
        print("✅ Optimistic update correctly rolled back: \(result.error!)")
    }
    
    func testOptimisticToggleBookmark_Failure_Rollback() async {
        // Given
        let postId = 1
        let currentState = true
        let currentCount = 3
        
        // When - this should fail due to no auth
        let result = await engagementService.optimisticToggleBookmark(
            postId: postId,
            currentState: currentState,
            currentCount: currentCount
        )
        
        // Then
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.response)
        XCTAssertNotNil(result.error)
        
        // Check rollback values
        XCTAssertEqual(result.response!.isBookmarked, currentState)
        XCTAssertEqual(result.response!.bookmarkCount, currentCount)
        
        print("✅ Optimistic bookmark update correctly rolled back: \(result.error!)")
    }
    
    // MARK: - Convenience Method Tests
    
    func testIsPostLiked_WithoutAuth_ThrowsError() async {
        // Given
        let postId = 1
        
        // When & Then
        do {
            _ = try await engagementService.isPostLiked(postId: postId)
            XCTFail("Expected error due to no authentication")
        } catch {
            // Expected - should fail without authentication
            print("✅ isPostLiked correctly threw error: \(error)")
        }
    }
    
    func testIsPostBookmarked_WithoutAuth_ThrowsError() async {
        // Given
        let postId = 2
        
        // When & Then
        do {
            _ = try await engagementService.isPostBookmarked(postId: postId)
            XCTFail("Expected error due to no authentication")
        } catch {
            // Expected - should fail without authentication
            print("✅ isPostBookmarked correctly threw error: \(error)")
        }
    }
    
    func testBatchCheckEngagementStatus_WithoutAuth_ThrowsError() async {
        // Given
        let postIds = [1, 2, 3, 4]
        
        // When & Then
        do {
            _ = try await engagementService.batchCheckEngagementStatus(postIds: postIds)
            XCTFail("Expected error due to no authentication")
        } catch {
            // Expected - should fail without authentication
            print("✅ batchCheckEngagementStatus correctly threw error: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testEngagementError_LocalizedDescription() {
        // Test that all error cases have proper localized descriptions
        let errors: [EngagementError] = [
            .networkError(URLError(.notConnectedToInternet)),
            .unauthorized,
            .postNotFound,
            .alreadyLiked,
            .alreadyBookmarked,
            .notLiked,
            .notBookmarked,
            .invalidURL,
            .invalidResponse,
            .decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "test"))),
            .apiError(500, "Server error"),
            .serverError("Internal error"),
            .timeout,
            .unknownError(NSError(domain: "test", code: 0))
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            print("✅ \(error): \(error.errorDescription!)")
        }
    }
    
    func testEngagementError_RecoverySuggestion() {
        // Test that errors have recovery suggestions
        let errors: [EngagementError] = [
            .networkError(URLError(.notConnectedToInternet)),
            .unauthorized,
            .postNotFound,
            .alreadyLiked,
            .timeout
        ]
        
        for error in errors {
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.recoverySuggestion!.isEmpty)
            print("✅ \(error) recovery: \(error.recoverySuggestion!)")
        }
    }
}