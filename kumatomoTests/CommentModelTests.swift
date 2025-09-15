import XCTest
@testable import kumatomo

class CommentModelTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func createTestUser() -> User {
        return User(
            id: 1,
            email: "test@example.com",
            name: "Test User",
            username: "testuser",
            profileImageURL: "https://example.com/profile.jpg",
            coverImageURL: nil,
            bio: "Test bio",
            location: "Tokyo",
            birthday: "1990-01-01",
            postCount: 10,
            followingCount: 5,
            followersCount: 15,
            hasCompletedSetup: true,
            createdAt: Date(),
            isVerified: false,
            joinedDate: "2023-01-01"
        )
    }
    
    private func createTestComment() -> Comment {
        return Comment(
            id: 1,
            postId: 100,
            userId: 1,
            content: "This is a test comment",
            imageUrl: "https://example.com/image.jpg",
            user: createTestUser()
        )
    }
    
    // MARK: - Initialization Tests
    
    func testCommentInitialization() {
        let comment = Comment(
            id: 1,
            postId: 100,
            userId: 1,
            content: "Test content",
            imageUrl: "https://example.com/image.jpg",
            user: createTestUser()
        )
        
        XCTAssertEqual(comment.id, 1)
        XCTAssertEqual(comment.postId, 100)
        XCTAssertEqual(comment.userId, 1)
        XCTAssertEqual(comment.content, "Test content")
        XCTAssertEqual(comment.imageUrl, "https://example.com/image.jpg")
        XCTAssertNotNil(comment.user)
        XCTAssertNotNil(comment.createdAt)
        XCTAssertNotNil(comment.updatedAt)
    }
    
    func testCommentInitializationWithoutOptionalFields() {
        let comment = Comment(
            postId: 100,
            userId: 1,
            content: "Test content"
        )
        
        XCTAssertEqual(comment.id, 0)
        XCTAssertEqual(comment.postId, 100)
        XCTAssertEqual(comment.userId, 1)
        XCTAssertEqual(comment.content, "Test content")
        XCTAssertNil(comment.imageUrl)
        XCTAssertNil(comment.user)
    }
    
    // MARK: - Codable Tests
    
    func testCommentEncoding() throws {
        let comment = createTestComment()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(comment)
        XCTAssertNotNil(data)
        
        // Verify the encoded JSON contains expected keys
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["id"] as? Int, 1)
        XCTAssertEqual(json?["post_id"] as? Int, 100)
        XCTAssertEqual(json?["user_id"] as? Int, 1)
        XCTAssertEqual(json?["content"] as? String, "This is a test comment")
        XCTAssertEqual(json?["image_url"] as? String, "https://example.com/image.jpg")
        XCTAssertNotNil(json?["created_at"])
        XCTAssertNotNil(json?["updated_at"])
        XCTAssertNotNil(json?["user"])
    }
    
    func testCommentDecoding() throws {
        let jsonString = """
        {
            "id": 1,
            "post_id": 100,
            "user_id": 1,
            "content": "This is a test comment",
            "image_url": "https://example.com/image.jpg",
            "created_at": "2023-12-01T10:00:00Z",
            "updated_at": "2023-12-01T10:00:00Z",
            "user": {
                "id": 1,
                "email": "test@example.com",
                "name": "Test User",
                "username": "testuser"
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let comment = try decoder.decode(Comment.self, from: data)
        
        XCTAssertEqual(comment.id, 1)
        XCTAssertEqual(comment.postId, 100)
        XCTAssertEqual(comment.userId, 1)
        XCTAssertEqual(comment.content, "This is a test comment")
        XCTAssertEqual(comment.imageUrl, "https://example.com/image.jpg")
        XCTAssertNotNil(comment.user)
        XCTAssertEqual(comment.user?.id, 1)
        XCTAssertEqual(comment.user?.name, "Test User")
    }
    
    func testCommentDecodingWithMissingOptionalFields() throws {
        let jsonString = """
        {
            "id": 1,
            "post_id": 100,
            "user_id": 1,
            "content": "This is a test comment",
            "created_at": "2023-12-01T10:00:00Z",
            "updated_at": "2023-12-01T10:00:00Z"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let comment = try decoder.decode(Comment.self, from: data)
        
        XCTAssertEqual(comment.id, 1)
        XCTAssertEqual(comment.postId, 100)
        XCTAssertEqual(comment.userId, 1)
        XCTAssertEqual(comment.content, "This is a test comment")
        XCTAssertNil(comment.imageUrl)
        XCTAssertNil(comment.user)
    }
    
    func testCommentDecodingWithAlternativeDateFormat() throws {
        let jsonString = """
        {
            "id": 1,
            "post_id": 100,
            "user_id": 1,
            "content": "This is a test comment",
            "created_at": "2023-12-01T10:00:00.123456Z",
            "updated_at": "2023-12-01T10:00:00.123456Z"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let comment = try decoder.decode(Comment.self, from: data)
        
        XCTAssertEqual(comment.id, 1)
        XCTAssertNotNil(comment.createdAt)
        XCTAssertNotNil(comment.updatedAt)
    }
    
    // MARK: - Extension Tests
    
    func testRelativeTimeString() {
        let comment = createTestComment()
        let relativeTime = comment.relativeTimeString
        XCTAssertFalse(relativeTime.isEmpty)
        // The exact string will depend on the current time, so we just check it's not empty
    }
    
    func testHasImage() {
        var comment = createTestComment()
        XCTAssertTrue(comment.hasImage)
        
        comment.imageUrl = nil
        XCTAssertFalse(comment.hasImage)
        
        comment.imageUrl = ""
        XCTAssertFalse(comment.hasImage)
    }
    
    func testHasContent() {
        var comment = createTestComment()
        XCTAssertTrue(comment.hasContent)
        
        comment.content = ""
        XCTAssertFalse(comment.hasContent)
        
        comment.content = "   "
        XCTAssertFalse(comment.hasContent)
        
        comment.content = "  Valid content  "
        XCTAssertTrue(comment.hasContent)
    }
    
    func testValidateContent() {
        var comment = createTestComment()
        XCTAssertTrue(comment.validateContent())
        
        comment.content = ""
        XCTAssertFalse(comment.validateContent())
        
        comment.content = String(repeating: "a", count: 500)
        XCTAssertTrue(comment.validateContent(maxLength: 500))
        
        comment.content = String(repeating: "a", count: 501)
        XCTAssertFalse(comment.validateContent(maxLength: 500))
    }
    
    // MARK: - Equatable Tests
    
    func testCommentEquality() {
        let comment1 = createTestComment()
        let comment2 = createTestComment()
        
        XCTAssertEqual(comment1, comment2)
        
        var comment3 = createTestComment()
        comment3.content = "Different content"
        XCTAssertNotEqual(comment1, comment3)
    }
}