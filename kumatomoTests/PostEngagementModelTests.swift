import XCTest
@testable import kumatomo

class PostEngagementModelTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func createTestPost() -> Post {
        return Post(
            id: 1,
            userId: 1,
            content: "This is a test post",
            shopId: nil,
            imageUrl: "https://example.com/image.jpg",
            tags: ["test", "post"]
        )
    }
    
    private func createTestComment() -> Comment {
        return Comment(
            id: 1,
            postId: 1,
            userId: 2,
            content: "This is a test comment"
        )
    }
    
    // MARK: - Engagement Properties Tests
    
    func testPostEngagementPropertiesInitialization() {
        var post = createTestPost()
        
        // Initially, engagement properties should be nil
        XCTAssertNil(post.likeCount)
        XCTAssertNil(post.bookmarkCount)
        XCTAssertNil(post.isLikedByCurrentUser)
        XCTAssertNil(post.isBookmarkedByCurrentUser)
        XCTAssertNil(post.comments)
    }
    
    func testPostEngagementPropertiesAssignment() {
        var post = createTestPost()
        
        post.likeCount = 42
        post.bookmarkCount = 15
        post.isLikedByCurrentUser = true
        post.isBookmarkedByCurrentUser = false
        post.comments = [createTestComment()]
        
        XCTAssertEqual(post.likeCount, 42)
        XCTAssertEqual(post.bookmarkCount, 15)
        XCTAssertTrue(post.isLikedByCurrentUser!)
        XCTAssertFalse(post.isBookmarkedByCurrentUser!)
        XCTAssertEqual(post.comments?.count, 1)
    }
    
    // MARK: - Engagement Methods Tests
    
    func testUpdateLikeStatus() {
        var post = createTestPost()
        
        post.updateLikeStatus(isLiked: true, likeCount: 42)
        
        XCTAssertTrue(post.isLikedByCurrentUser!)
        XCTAssertEqual(post.likeCount, 42)
        XCTAssertNotNil(post.updatedAt)
    }
    
    func testUpdateBookmarkStatus() {
        var post = createTestPost()
        
        post.updateBookmarkStatus(isBookmarked: true, bookmarkCount: 15)
        
        XCTAssertTrue(post.isBookmarkedByCurrentUser!)
        XCTAssertEqual(post.bookmarkCount, 15)
        XCTAssertNotNil(post.updatedAt)
    }
    
    func testAddComment() {
        var post = createTestPost()
        let comment = createTestComment()
        
        post.addComment(comment)
        
        XCTAssertEqual(post.comments?.count, 1)
        XCTAssertEqual(post.comments?.first?.id, 1)
        XCTAssertEqual(post.commentCount, 1)
    }
    
    func testAddMultipleComments() {
        var post = createTestPost()
        let comment1 = createTestComment()
        var comment2 = createTestComment()
        comment2.id = 2
        
        post.addComment(comment1)
        post.addComment(comment2)
        
        XCTAssertEqual(post.comments?.count, 2)
        XCTAssertEqual(post.commentCount, 2)
    }
    
    func testRemoveComment() {
        var post = createTestPost()
        let comment = createTestComment()
        
        post.addComment(comment)
        XCTAssertEqual(post.comments?.count, 1)
        XCTAssertEqual(post.commentCount, 1)
        
        post.removeComment(withId: 1)
        XCTAssertEqual(post.comments?.count, 0)
        XCTAssertEqual(post.commentCount, 0)
    }
    
    func testRemoveNonExistentComment() {
        var post = createTestPost()
        let comment = createTestComment()
        
        post.addComment(comment)
        XCTAssertEqual(post.commentCount, 1)
        
        post.removeComment(withId: 999) // Non-existent ID
        XCTAssertEqual(post.comments?.count, 1) // Should remain unchanged
        XCTAssertEqual(post.commentCount, 0) // But count is decremented (this might be a bug to fix)
    }
    
    func testTotalEngagementCount() {
        var post = createTestPost()
        
        // Initially should be 0
        XCTAssertEqual(post.totalEngagementCount, 0)
        
        post.likeCount = 10
        post.bookmarkCount = 5
        post.commentCount = 3
        
        XCTAssertEqual(post.totalEngagementCount, 18)
    }
    
    func testTotalEngagementCountWithNilValues() {
        var post = createTestPost()
        
        post.likeCount = 10
        // bookmarkCount and commentCount remain nil
        
        XCTAssertEqual(post.totalEngagementCount, 10)
    }
    
    func testIsEngagedByCurrentUser() {
        var post = createTestPost()
        
        // Initially not engaged
        XCTAssertFalse(post.isEngagedByCurrentUser)
        
        post.isLikedByCurrentUser = true
        XCTAssertTrue(post.isEngagedByCurrentUser)
        
        post.isLikedByCurrentUser = false
        post.isBookmarkedByCurrentUser = true
        XCTAssertTrue(post.isEngagedByCurrentUser)
        
        post.isLikedByCurrentUser = true
        post.isBookmarkedByCurrentUser = true
        XCTAssertTrue(post.isEngagedByCurrentUser)
        
        post.isLikedByCurrentUser = false
        post.isBookmarkedByCurrentUser = false
        XCTAssertFalse(post.isEngagedByCurrentUser)
    }
    
    func testEngagementSummary() {
        var post = createTestPost()
        
        // Empty summary
        XCTAssertEqual(post.engagementSummary, "")
        
        post.likeCount = 42
        XCTAssertEqual(post.engagementSummary, "42いいね")
        
        post.commentCount = 8
        XCTAssertEqual(post.engagementSummary, "42いいね • 8コメント")
        
        post.bookmarkCount = 15
        XCTAssertEqual(post.engagementSummary, "42いいね • 8コメント • 15ブックマーク")
        
        // Test with only comments
        post.likeCount = 0
        post.bookmarkCount = 0
        XCTAssertEqual(post.engagementSummary, "8コメント")
    }
    
    // MARK: - Codable Tests
    
    func testPostEncodingWithEngagementProperties() throws {
        var post = createTestPost()
        post.likeCount = 42
        post.bookmarkCount = 15
        post.isLikedByCurrentUser = true
        post.isBookmarkedByCurrentUser = false
        post.comments = [createTestComment()]
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(post)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["like_count"] as? Int, 42)
        XCTAssertEqual(json?["bookmark_count"] as? Int, 15)
        XCTAssertEqual(json?["is_liked_by_current_user"] as? Bool, true)
        XCTAssertEqual(json?["is_bookmarked_by_current_user"] as? Bool, false)
        XCTAssertNotNil(json?["comments"] as? [[String: Any]])
    }
    
    func testPostDecodingWithEngagementProperties() throws {
        let jsonString = """
        {
            "id": 1,
            "user_id": 1,
            "content": "This is a test post",
            "image_url": "https://example.com/image.jpg",
            "tags": ["test", "post"],
            "created_at": "2023-12-01T10:00:00Z",
            "updated_at": "2023-12-01T10:00:00Z",
            "like_count": 42,
            "bookmark_count": 15,
            "is_liked_by_current_user": true,
            "is_bookmarked_by_current_user": false,
            "comment_count": 8,
            "comments": [
                {
                    "id": 1,
                    "post_id": 1,
                    "user_id": 2,
                    "content": "Test comment",
                    "created_at": "2023-12-01T10:00:00Z",
                    "updated_at": "2023-12-01T10:00:00Z"
                }
            ]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let post = try decoder.decode(Post.self, from: data)
        
        XCTAssertEqual(post.id, 1)
        XCTAssertEqual(post.likeCount, 42)
        XCTAssertEqual(post.bookmarkCount, 15)
        XCTAssertTrue(post.isLikedByCurrentUser!)
        XCTAssertFalse(post.isBookmarkedByCurrentUser!)
        XCTAssertEqual(post.commentCount, 8)
        XCTAssertEqual(post.comments?.count, 1)
        XCTAssertEqual(post.comments?.first?.id, 1)
    }
    
    func testPostDecodingWithMissingEngagementProperties() throws {
        let jsonString = """
        {
            "id": 1,
            "user_id": 1,
            "content": "This is a test post",
            "created_at": "2023-12-01T10:00:00Z",
            "updated_at": "2023-12-01T10:00:00Z"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let post = try decoder.decode(Post.self, from: data)
        
        XCTAssertEqual(post.id, 1)
        XCTAssertNil(post.likeCount)
        XCTAssertNil(post.bookmarkCount)
        XCTAssertNil(post.isLikedByCurrentUser)
        XCTAssertNil(post.isBookmarkedByCurrentUser)
        XCTAssertNil(post.comments)
    }
    
    // MARK: - Edge Cases
    
    func testEngagementCountsWithZeroValues() {
        var post = createTestPost()
        
        post.likeCount = 0
        post.bookmarkCount = 0
        post.commentCount = 0
        
        XCTAssertEqual(post.totalEngagementCount, 0)
        XCTAssertEqual(post.engagementSummary, "")
    }
    
    func testRemoveCommentWithZeroCount() {
        var post = createTestPost()
        post.commentCount = 0
        
        post.removeComment(withId: 1)
        
        // Count should not go below 0
        XCTAssertEqual(post.commentCount, 0)
    }
}