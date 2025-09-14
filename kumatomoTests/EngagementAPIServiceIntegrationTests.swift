import XCTest
@testable import kumatomo

/// Integration tests for EngagementAPIService that test against the actual Laravel API
/// These tests require the Laravel API to be running on localhost:8000
@MainActor
class EngagementAPIServiceIntegrationTests: XCTestCase {
    
    var engagementService: EngagementAPIService!
    var testPostId: Int = 1 // Assuming there's a test post with ID 1
    
    override func setUp() {
        super.setUp()
        engagementService = EngagementAPIService.shared
        
        // Set up test environment
        setenv("API_BASE_URL", "http://localhost:8000/api", 1)
        
        // For integration tests, we would need a valid auth token
        // In a real test environment, you would set up test authentication
        // AuthTokenManager.shared.token = "test_token_here"
    }
    
    override func tearDown() {
        engagementService = nil
        AuthTokenManager.shared.clearToken()
        super.tearDown()
    }
    
    // MARK: - API Endpoint Availability Tests
    
    func testAPIEndpointAvailability() async throws {
        // Test that the API base endpoint is reachable
        let url = URL(string: "http://localhost:8000/api/")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }
        
        XCTAssertEqual(httpResponse.statusCode, 200)
        
        // Parse the response to verify API is working
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["message"] as? String, "kumatomo API is working!")
    }
    
    // MARK: - Engagement API Structure Tests
    
    func testEngagementEndpointsExist() async throws {
        // Test that engagement endpoints are properly configured
        let endpoints = [
            "http://localhost:8000/api/posts/1/like",
            "http://localhost:8000/api/posts/1/bookmark",
            "http://localhost:8000/api/user/liked-posts",
            "http://localhost:8000/api/user/bookmarked-posts"
        ]
        
        for endpoint in endpoints {
            let url = URL(string: endpoint)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST" // For like/bookmark endpoints
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    XCTFail("Invalid response type for \(endpoint)")
                    continue
                }
                
                // We expect 401 (unauthorized) since we don't have auth token
                // This confirms the endpoint exists and is protected
                XCTAssertTrue([401, 422].contains(httpResponse.statusCode), 
                             "Endpoint \(endpoint) should return 401 or 422, got \(httpResponse.statusCode)")
                
            } catch {
                XCTFail("Failed to reach endpoint \(endpoint): \(error)")
            }
        }
    }
    
    // MARK: - Content Validation Integration Tests
    
    func testEngagementServiceInitialization() {
        // Test that the service initializes correctly
        XCTAssertNotNil(engagementService)
        
        // Test singleton pattern
        let anotherInstance = EngagementAPIService.shared
        XCTAssertTrue(engagementService === anotherInstance)
    }
    
    func testEngagementErrorHandling() {
        // Test that all error cases have proper descriptions
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
            .timeout
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            XCTAssertNotNil(error.recoverySuggestion)
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testToggleLike_UnauthorizedError() async {
        // Test that unauthorized requests are properly handled
        do {
            _ = try await engagementService.toggleLike(postId: testPostId)
            XCTFail("Expected EngagementError due to no authentication")
        } catch let error as EngagementError {
            // Should get unauthorized or network error
            switch error {
            case .unauthorized, .networkError, .apiError:
                // Expected errors
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            // Network errors are also acceptable in test environment
            print("Network error (expected): \(error)")
        }
    }
    
    func testToggleBookmark_UnauthorizedError() async {
        // Test that unauthorized requests are properly handled
        do {
            _ = try await engagementService.toggleBookmark(postId: testPostId)
            XCTFail("Expected EngagementError due to no authentication")
        } catch let error as EngagementError {
            // Should get unauthorized or network error
            switch error {
            case .unauthorized, .networkError, .apiError:
                // Expected errors
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            // Network errors are also acceptable in test environment
            print("Network error (expected): \(error)")
        }
    }
    
    func testFetchLikedPosts_UnauthorizedError() async {
        // Test that unauthorized requests are properly handled
        do {
            _ = try await engagementService.fetchLikedPosts()
            XCTFail("Expected EngagementError due to no authentication")
        } catch let error as EngagementError {
            // Should get unauthorized or network error
            switch error {
            case .unauthorized, .networkError, .apiError:
                // Expected errors
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            // Network errors are also acceptable in test environment
            print("Network error (expected): \(error)")
        }
    }
    
    func testFetchBookmarkedPosts_UnauthorizedError() async {
        // Test that unauthorized requests are properly handled
        do {
            _ = try await engagementService.fetchBookmarkedPosts()
            XCTFail("Expected EngagementError due to no authentication")
        } catch let error as EngagementError {
            // Should get unauthorized or network error
            switch error {
            case .unauthorized, .networkError, .apiError:
                // Expected errors
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            // Network errors are also acceptable in test environment
            print("Network error (expected): \(error)")
        }
    }
    
    // MARK: - URL Construction Integration Tests
    
    func testURLConstruction() {
        // Test that URLs are constructed correctly
        let baseURL = "http://localhost:8000/api"
        
        // Test like endpoint URL construction
        let likeEndpoint = "\(baseURL)/posts/1/like"
        XCTAssertNotNil(URL(string: likeEndpoint))
        
        // Test bookmark endpoint URL construction
        let bookmarkEndpoint = "\(baseURL)/posts/1/bookmark"
        XCTAssertNotNil(URL(string: bookmarkEndpoint))
        
        // Test liked posts endpoint URL construction
        let likedPostsEndpoint = "\(baseURL)/user/liked-posts"
        XCTAssertNotNil(URL(string: likedPostsEndpoint))
        
        // Test bookmarked posts endpoint URL construction
        let bookmarkedPostsEndpoint = "\(baseURL)/user/bookmarked-posts"
        XCTAssertNotNil(URL(string: bookmarkedPostsEndpoint))
    }
    
    // MARK: - Optimistic Update Integration Tests
    
    func testOptimisticUpdateRollback() async {
        // Test that optimistic updates properly rollback on failure
        let initialState = false
        let initialCount = 5
        
        let result = await engagementService.optimisticToggleLike(
            postId: testPostId,
            currentState: initialState,
            currentCount: initialCount
        )
        
        // Should fail due to no authentication
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.response)
        XCTAssertNotNil(result.error)
        
        // Should rollback to original values
        XCTAssertEqual(result.response!.isLiked, initialState)
        XCTAssertEqual(result.response!.likeCount, initialCount)
    }
    
    func testOptimisticBookmarkUpdateRollback() async {
        // Test that optimistic bookmark updates properly rollback on failure
        let initialState = true
        let initialCount = 3
        
        let result = await engagementService.optimisticToggleBookmark(
            postId: testPostId,
            currentState: initialState,
            currentCount: initialCount
        )
        
        // Should fail due to no authentication
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.response)
        XCTAssertNotNil(result.error)
        
        // Should rollback to original values
        XCTAssertEqual(result.response!.isBookmarked, initialState)
        XCTAssertEqual(result.response!.bookmarkCount, initialCount)
    }
    
    // MARK: - Response Model Integration Tests
    
    func testLikeResponseModel() {
        // Test LikeResponse model
        let likeResponse = LikeResponse(isLiked: true, likeCount: 10)
        XCTAssertTrue(likeResponse.isLiked)
        XCTAssertEqual(likeResponse.likeCount, 10)
        
        // Test encoding/decoding
        do {
            let encoded = try JSONEncoder().encode(likeResponse)
            let decoded = try JSONDecoder().decode(LikeResponse.self, from: encoded)
            XCTAssertEqual(decoded, likeResponse)
        } catch {
            XCTFail("Failed to encode/decode LikeResponse: \(error)")
        }
    }
    
    func testBookmarkResponseModel() {
        // Test BookmarkResponse model
        let bookmarkResponse = BookmarkResponse(isBookmarked: false, bookmarkCount: 7)
        XCTAssertFalse(bookmarkResponse.isBookmarked)
        XCTAssertEqual(bookmarkResponse.bookmarkCount, 7)
        
        // Test encoding/decoding
        do {
            let encoded = try JSONEncoder().encode(bookmarkResponse)
            let decoded = try JSONDecoder().decode(BookmarkResponse.self, from: encoded)
            XCTAssertEqual(decoded, bookmarkResponse)
        } catch {
            XCTFail("Failed to encode/decode BookmarkResponse: \(error)")
        }
    }
    
    // MARK: - Convenience Method Integration Tests
    
    func testConvenienceMethodsWithoutAuth() async {
        // Test convenience methods fail appropriately without auth
        do {
            _ = try await engagementService.isPostLiked(postId: testPostId)
            XCTFail("Expected error due to no authentication")
        } catch {
            // Expected
            print("isPostLiked correctly failed: \(error)")
        }
        
        do {
            _ = try await engagementService.isPostBookmarked(postId: testPostId)
            XCTFail("Expected error due to no authentication")
        } catch {
            // Expected
            print("isPostBookmarked correctly failed: \(error)")
        }
        
        do {
            _ = try await engagementService.batchCheckEngagementStatus(postIds: [1, 2, 3])
            XCTFail("Expected error due to no authentication")
        } catch {
            // Expected
            print("batchCheckEngagementStatus correctly failed: \(error)")
        }
    }
}

// MARK: - Test Configuration

extension EngagementAPIServiceIntegrationTests {
    
    /// Check if the Laravel API is running and accessible
    func isAPIAvailable() async -> Bool {
        do {
            let url = URL(string: "http://localhost:8000/api/")!
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
    
    /// Helper method to skip tests if API is not available
    func skipIfAPINotAvailable() async throws {
        let isAvailable = await isAPIAvailable()
        try XCTSkipUnless(isAvailable, "Laravel API is not running on localhost:8000")
    }
}