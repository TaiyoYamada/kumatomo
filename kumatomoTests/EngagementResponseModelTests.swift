import XCTest
@testable import kumatomo

class EngagementResponseModelTests: XCTestCase {
    
    // MARK: - LikeResponse Tests
    
    func testLikeResponseInitialization() {
        let likeResponse = LikeResponse(isLiked: true, likeCount: 42)
        
        XCTAssertTrue(likeResponse.isLiked)
        XCTAssertEqual(likeResponse.likeCount, 42)
    }
    
    func testLikeResponseEncoding() throws {
        let likeResponse = LikeResponse(isLiked: true, likeCount: 42)
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(likeResponse)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["is_liked"] as? Bool, true)
        XCTAssertEqual(json?["like_count"] as? Int, 42)
    }
    
    func testLikeResponseDecoding() throws {
        let jsonString = """
        {
            "is_liked": true,
            "like_count": 42
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let likeResponse = try decoder.decode(LikeResponse.self, from: data)
        
        XCTAssertTrue(likeResponse.isLiked)
        XCTAssertEqual(likeResponse.likeCount, 42)
    }
    
    func testLikeResponseEquality() {
        let response1 = LikeResponse(isLiked: true, likeCount: 42)
        let response2 = LikeResponse(isLiked: true, likeCount: 42)
        let response3 = LikeResponse(isLiked: false, likeCount: 42)
        
        XCTAssertEqual(response1, response2)
        XCTAssertNotEqual(response1, response3)
    }
    
    // MARK: - BookmarkResponse Tests
    
    func testBookmarkResponseInitialization() {
        let bookmarkResponse = BookmarkResponse(isBookmarked: false, bookmarkCount: 15)
        
        XCTAssertFalse(bookmarkResponse.isBookmarked)
        XCTAssertEqual(bookmarkResponse.bookmarkCount, 15)
    }
    
    func testBookmarkResponseEncoding() throws {
        let bookmarkResponse = BookmarkResponse(isBookmarked: false, bookmarkCount: 15)
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(bookmarkResponse)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["is_bookmarked"] as? Bool, false)
        XCTAssertEqual(json?["bookmark_count"] as? Int, 15)
    }
    
    func testBookmarkResponseDecoding() throws {
        let jsonString = """
        {
            "is_bookmarked": false,
            "bookmark_count": 15
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let bookmarkResponse = try decoder.decode(BookmarkResponse.self, from: data)
        
        XCTAssertFalse(bookmarkResponse.isBookmarked)
        XCTAssertEqual(bookmarkResponse.bookmarkCount, 15)
    }
    
    func testBookmarkResponseEquality() {
        let response1 = BookmarkResponse(isBookmarked: false, bookmarkCount: 15)
        let response2 = BookmarkResponse(isBookmarked: false, bookmarkCount: 15)
        let response3 = BookmarkResponse(isBookmarked: true, bookmarkCount: 15)
        
        XCTAssertEqual(response1, response2)
        XCTAssertNotEqual(response1, response3)
    }
    
    // MARK: - EngagementStatus Tests
    
    func testEngagementStatusInitialization() {
        let status = EngagementStatus(
            isLiked: true,
            isBookmarked: false,
            likeCount: 42,
            bookmarkCount: 15,
            commentCount: 8
        )
        
        XCTAssertTrue(status.isLiked)
        XCTAssertFalse(status.isBookmarked)
        XCTAssertEqual(status.likeCount, 42)
        XCTAssertEqual(status.bookmarkCount, 15)
        XCTAssertEqual(status.commentCount, 8)
    }
    
    func testEngagementStatusDefaultInitialization() {
        let status = EngagementStatus()
        
        XCTAssertFalse(status.isLiked)
        XCTAssertFalse(status.isBookmarked)
        XCTAssertEqual(status.likeCount, 0)
        XCTAssertEqual(status.bookmarkCount, 0)
        XCTAssertEqual(status.commentCount, 0)
    }
    
    func testEngagementStatusEncoding() throws {
        let status = EngagementStatus(
            isLiked: true,
            isBookmarked: false,
            likeCount: 42,
            bookmarkCount: 15,
            commentCount: 8
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(status)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["is_liked"] as? Bool, true)
        XCTAssertEqual(json?["is_bookmarked"] as? Bool, false)
        XCTAssertEqual(json?["like_count"] as? Int, 42)
        XCTAssertEqual(json?["bookmark_count"] as? Int, 15)
        XCTAssertEqual(json?["comment_count"] as? Int, 8)
    }
    
    func testEngagementStatusDecoding() throws {
        let jsonString = """
        {
            "is_liked": true,
            "is_bookmarked": false,
            "like_count": 42,
            "bookmark_count": 15,
            "comment_count": 8
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let status = try decoder.decode(EngagementStatus.self, from: data)
        
        XCTAssertTrue(status.isLiked)
        XCTAssertFalse(status.isBookmarked)
        XCTAssertEqual(status.likeCount, 42)
        XCTAssertEqual(status.bookmarkCount, 15)
        XCTAssertEqual(status.commentCount, 8)
    }
    
    // MARK: - CommentCreateRequest Tests
    
    func testCommentCreateRequestInitialization() {
        let request = CommentCreateRequest(
            content: "This is a test comment",
            imageUrl: "https://example.com/image.jpg"
        )
        
        XCTAssertEqual(request.content, "This is a test comment")
        XCTAssertEqual(request.imageUrl, "https://example.com/image.jpg")
    }
    
    func testCommentCreateRequestInitializationWithoutImage() {
        let request = CommentCreateRequest(content: "This is a test comment")
        
        XCTAssertEqual(request.content, "This is a test comment")
        XCTAssertNil(request.imageUrl)
    }
    
    func testCommentCreateRequestEncoding() throws {
        let request = CommentCreateRequest(
            content: "This is a test comment",
            imageUrl: "https://example.com/image.jpg"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["content"] as? String, "This is a test comment")
        XCTAssertEqual(json?["image_url"] as? String, "https://example.com/image.jpg")
    }
    
    func testCommentCreateRequestDecoding() throws {
        let jsonString = """
        {
            "content": "This is a test comment",
            "image_url": "https://example.com/image.jpg"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let request = try decoder.decode(CommentCreateRequest.self, from: data)
        
        XCTAssertEqual(request.content, "This is a test comment")
        XCTAssertEqual(request.imageUrl, "https://example.com/image.jpg")
    }
    
    // MARK: - CommentResponse Tests
    
    func testCommentResponseInitialization() {
        let comment = Comment(
            id: 1,
            postId: 100,
            userId: 1,
            content: "Test comment"
        )
        
        let response = CommentResponse(
            comment: comment,
            success: true,
            message: "Comment created successfully"
        )
        
        XCTAssertEqual(response.comment.id, 1)
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Comment created successfully")
    }
    
    func testCommentResponseDefaultInitialization() {
        let comment = Comment(
            id: 1,
            postId: 100,
            userId: 1,
            content: "Test comment"
        )
        
        let response = CommentResponse(comment: comment)
        
        XCTAssertEqual(response.comment.id, 1)
        XCTAssertTrue(response.success)
        XCTAssertNil(response.message)
    }
    
    func testCommentResponseEncoding() throws {
        let comment = Comment(
            id: 1,
            postId: 100,
            userId: 1,
            content: "Test comment"
        )
        
        let response = CommentResponse(
            comment: comment,
            success: true,
            message: "Success"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["comment"])
        XCTAssertEqual(json?["success"] as? Bool, true)
        XCTAssertEqual(json?["message"] as? String, "Success")
    }
}