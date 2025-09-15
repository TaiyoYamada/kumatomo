import XCTest
@testable import kumatomo

class PostAPIServiceEngagementTests: XCTestCase {
    
    var postAPIService: PostAPIService!
    var mockSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        postAPIService = PostAPIService.shared
        mockSession = MockURLSession()
        // Note: In a real implementation, you would inject the mock session
    }
    
    override func tearDown() {
        postAPIService = nil
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - fetchAllPosts Tests
    
    func testFetchAllPosts_WithEngagementData_Success() async throws {
        // Given
        let mockPostsJSON = """
        [
            {
                "id": 1,
                "user_id": 1,
                "content": "Test post",
                "like_count": 5,
                "bookmark_count": 2,
                "comment_count": 3,
                "is_liked_by_current_user": true,
                "is_bookmarked_by_current_user": false,
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
                "user": {
                    "id": 1,
                    "name": "Test User",
                    "username": "testuser"
                },
                "images": []
            }
        ]
        """
        
        mockSession.mockData = mockPostsJSON.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/posts")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let posts = try await postAPIService.fetchAllPosts()
        
        // Then
        XCTAssertEqual(posts.count, 1)
        let post = posts.first!
        XCTAssertEqual(post.id, 1)
        XCTAssertEqual(post.likeCount, 5)
        XCTAssertEqual(post.bookmarkCount, 2)
        XCTAssertEqual(post.commentCount, 3)
        XCTAssertEqual(post.isLikedByCurrentUser, true)
        XCTAssertEqual(post.isBookmarkedByCurrentUser, false)
    }
    
    func testFetchAllPosts_WithoutAuthentication_Success() async throws {
        // Given
        let mockPostsJSON = """
        [
            {
                "id": 1,
                "user_id": 1,
                "content": "Test post",
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
                "user": {
                    "id": 1,
                    "name": "Test User",
                    "username": "testuser"
                },
                "images": []
            }
        ]
        """
        
        mockSession.mockData = mockPostsJSON.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/posts")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let posts = try await postAPIService.fetchAllPosts()
        
        // Then
        XCTAssertEqual(posts.count, 1)
        let post = posts.first!
        XCTAssertEqual(post.id, 1)
        XCTAssertNil(post.likeCount)
        XCTAssertNil(post.bookmarkCount)
        XCTAssertNil(post.isLikedByCurrentUser)
        XCTAssertNil(post.isBookmarkedByCurrentUser)
    }
    
    func testFetchAllPosts_EngagementDataError_ThrowsError() async {
        // Given
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/posts")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.mockData = "Internal Server Error".data(using: .utf8)
        
        // When & Then
        do {
            _ = try await postAPIService.fetchAllPosts()
            XCTFail("Expected error to be thrown")
        } catch let error as PostAPIError {
            XCTAssertTrue(error.isEngagementRelated)
            XCTAssertTrue(error.isRecoverable)
        } catch {
            XCTFail("Expected PostAPIError, got \(error)")
        }
    }
    
    // MARK: - fetchPost Tests
    
    func testFetchPost_WithEngagementDataAndComments_Success() async throws {
        // Given
        let mockPostJSON = """
        {
            "id": 1,
            "user_id": 1,
            "content": "Test post",
            "like_count": 10,
            "bookmark_count": 5,
            "comment_count": 2,
            "is_liked_by_current_user": false,
            "is_bookmarked_by_current_user": true,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z",
            "user": {
                "id": 1,
                "name": "Test User",
                "username": "testuser"
            },
            "comments": [
                {
                    "id": 1,
                    "post_id": 1,
                    "user_id": 2,
                    "content": "Great post!",
                    "created_at": "2024-01-01T01:00:00Z",
                    "updated_at": "2024-01-01T01:00:00Z",
                    "user": {
                        "id": 2,
                        "name": "Commenter",
                        "username": "commenter"
                    }
                }
            ],
            "images": []
        }
        """
        
        mockSession.mockData = mockPostJSON.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/posts/1")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let post = try await postAPIService.fetchPost(postId: 1)
        
        // Then
        XCTAssertEqual(post.id, 1)
        XCTAssertEqual(post.likeCount, 10)
        XCTAssertEqual(post.bookmarkCount, 5)
        XCTAssertEqual(post.commentCount, 2)
        XCTAssertEqual(post.isLikedByCurrentUser, false)
        XCTAssertEqual(post.isBookmarkedByCurrentUser, true)
        XCTAssertEqual(post.comments?.count, 1)
        XCTAssertEqual(post.comments?.first?.content, "Great post!")
    }
    
    func testFetchPost_NotFound_ThrowsError() async {
        // Given
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/posts/999")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.mockData = "Post not found".data(using: .utf8)
        
        // When & Then
        do {
            _ = try await postAPIService.fetchPost(postId: 999)
            XCTFail("Expected error to be thrown")
        } catch let error as PostAPIError {
            if case .apiError(let code, _) = error {
                XCTAssertEqual(code, 404)
            } else {
                XCTFail("Expected apiError with 404 code")
            }
        } catch {
            XCTFail("Expected PostAPIError, got \(error)")
        }
    }
    
    // MARK: - createPost Tests
    
    func testCreatePost_WithEngagementData_Success() async throws {
        // Given
        let mockPostJSON = """
        {
            "id": 1,
            "user_id": 1,
            "content": "New test post",
            "like_count": 0,
            "bookmark_count": 0,
            "comment_count": 0,
            "is_liked_by_current_user": false,
            "is_bookmarked_by_current_user": false,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z",
            "user": {
                "id": 1,
                "name": "Test User",
                "username": "testuser"
            },
            "images": []
        }
        """
        
        mockSession.mockData = mockPostJSON.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/posts")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let post = try await postAPIService.createPost(
            userId: 1,
            content: "New test post",
            tags: ["test"]
        )
        
        // Then
        XCTAssertEqual(post.id, 1)
        XCTAssertEqual(post.content, "New test post")
        XCTAssertEqual(post.likeCount, 0)
        XCTAssertEqual(post.bookmarkCount, 0)
        XCTAssertEqual(post.commentCount, 0)
        XCTAssertEqual(post.isLikedByCurrentUser, false)
        XCTAssertEqual(post.isBookmarkedByCurrentUser, false)
    }
    
    func testCreatePost_WithoutAuthentication_ThrowsError() async {
        // Given - No authentication token
        
        // When & Then
        do {
            _ = try await postAPIService.createPost(
                userId: 1,
                content: "Test post"
            )
            XCTFail("Expected error to be thrown")
        } catch let error as PostAPIError {
            if case .apiError(let code, _) = error {
                XCTAssertEqual(code, 401)
            } else {
                XCTFail("Expected apiError with 401 code")
            }
        } catch {
            XCTFail("Expected PostAPIError, got \(error)")
        }
    }
    
    // MARK: - updatePost Tests
    
    func testUpdatePost_WithEngagementDataPreserved_Success() async throws {
        // Given
        let mockPostJSON = """
        {
            "id": 1,
            "user_id": 1,
            "content": "Updated test post",
            "like_count": 5,
            "bookmark_count": 2,
            "comment_count": 3,
            "is_liked_by_current_user": true,
            "is_bookmarked_by_current_user": false,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T01:00:00Z",
            "user": {
                "id": 1,
                "name": "Test User",
                "username": "testuser"
            },
            "images": []
        }
        """
        
        mockSession.mockData = mockPostJSON.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/posts/1")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let post = try await postAPIService.updatePost(
            postId: 1,
            content: "Updated test post",
            tags: ["updated"]
        )
        
        // Then
        XCTAssertEqual(post.id, 1)
        XCTAssertEqual(post.content, "Updated test post")
        // Engagement data should be preserved
        XCTAssertEqual(post.likeCount, 5)
        XCTAssertEqual(post.bookmarkCount, 2)
        XCTAssertEqual(post.commentCount, 3)
        XCTAssertEqual(post.isLikedByCurrentUser, true)
        XCTAssertEqual(post.isBookmarkedByCurrentUser, false)
    }
    
    func testUpdatePost_InsufficientPermissions_ThrowsError() async {
        // Given
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/posts/1")!,
            statusCode: 403,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.mockData = "Forbidden".data(using: .utf8)
        
        // When & Then
        do {
            _ = try await postAPIService.updatePost(
                postId: 1,
                content: "Updated content"
            )
            XCTFail("Expected error to be thrown")
        } catch let error as PostAPIError {
            if case .apiError(let code, _) = error {
                XCTAssertEqual(code, 403)
            } else {
                XCTFail("Expected apiError with 403 code")
            }
        } catch {
            XCTFail("Expected PostAPIError, got \(error)")
        }
    }
    
    // MARK: - fetchUserPosts Tests
    
    func testFetchUserPosts_WithEngagementData_Success() async throws {
        // Given
        let mockPostsJSON = """
        [
            {
                "id": 1,
                "user_id": 1,
                "content": "User post 1",
                "like_count": 3,
                "bookmark_count": 1,
                "comment_count": 2,
                "is_liked_by_current_user": false,
                "is_bookmarked_by_current_user": true,
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
                "user": {
                    "id": 1,
                    "name": "Test User",
                    "username": "testuser"
                },
                "images": []
            }
        ]
        """
        
        mockSession.mockData = mockPostsJSON.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/users/1/posts")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let posts = try await postAPIService.fetchUserPosts(userId: 1)
        
        // Then
        XCTAssertEqual(posts.count, 1)
        let post = posts.first!
        XCTAssertEqual(post.id, 1)
        XCTAssertEqual(post.userId, 1)
        XCTAssertEqual(post.likeCount, 3)
        XCTAssertEqual(post.bookmarkCount, 1)
        XCTAssertEqual(post.commentCount, 2)
        XCTAssertEqual(post.isLikedByCurrentUser, false)
        XCTAssertEqual(post.isBookmarkedByCurrentUser, true)
    }
    
    // MARK: - Pagination Tests
    
    func testFetchAllPostsPaginated_WithEngagementData_Success() async throws {
        // Given
        let mockPostsJSON = """
        [
            {
                "id": 1,
                "user_id": 1,
                "content": "Paginated post",
                "like_count": 7,
                "bookmark_count": 3,
                "comment_count": 1,
                "is_liked_by_current_user": true,
                "is_bookmarked_by_current_user": true,
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
                "user": {
                    "id": 1,
                    "name": "Test User",
                    "username": "testuser"
                },
                "images": []
            }
        ]
        """
        
        mockSession.mockData = mockPostsJSON.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/posts?page=1&limit=10")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let posts = try await postAPIService.fetchAllPosts(page: 1, limit: 10)
        
        // Then
        XCTAssertEqual(posts.count, 1)
        let post = posts.first!
        XCTAssertEqual(post.likeCount, 7)
        XCTAssertEqual(post.bookmarkCount, 3)
        XCTAssertEqual(post.commentCount, 1)
        XCTAssertEqual(post.isLikedByCurrentUser, true)
        XCTAssertEqual(post.isBookmarkedByCurrentUser, true)
    }
    
    // MARK: - Error Handling Tests
    
    func testPostAPIError_EngagementRelatedProperties() {
        // Given
        let engagementError = PostAPIError.engagementDataError("Failed to load engagement data")
        let serverError = PostAPIError.apiError(500, "Internal server error")
        let networkError = PostAPIError.networkError(NSError(domain: "test", code: 0))
        let authError = PostAPIError.authenticationRequired
        
        // Then
        XCTAssertTrue(engagementError.isEngagementRelated)
        XCTAssertTrue(engagementError.isRecoverable)
        
        XCTAssertTrue(serverError.isEngagementRelated)
        XCTAssertFalse(serverError.isRecoverable)
        
        XCTAssertFalse(networkError.isEngagementRelated)
        XCTAssertTrue(networkError.isRecoverable)
        
        XCTAssertFalse(authError.isEngagementRelated)
        XCTAssertFalse(authError.isRecoverable)
    }
}

// MARK: - Mock Classes

class MockURLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw PostAPIError.invalidResponse
        }
        
        return (data, response)
    }
}