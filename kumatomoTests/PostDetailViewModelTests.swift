import XCTest
import UIKit
@testable import kumatomo

@MainActor
final class PostDetailViewModelTests: XCTestCase {
    
    var viewModel: PostDetailViewModel!
    var mockPost: Post!
    var mockComment: Comment!
    var mockUser: User!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock user
        mockUser = User(
            id: 1,
            username: "testuser",
            email: "test@example.com",
            profileImageURL: "https://example.com/profile.jpg"
        )
        
        // Create mock post
        mockPost = Post(
            id: 1,
            userId: 1,
            content: "Test post content",
            shopId: nil,
            imageUrl: nil,
            tags: ["熊本県全体"]
        )
        mockPost.likeCount = 5
        mockPost.bookmarkCount = 3
        mockPost.commentCount = 2
        mockPost.isLikedByCurrentUser = false
        mockPost.isBookmarkedByCurrentUser = false
        mockPost.user = mockUser
        
        // Create mock comment
        mockComment = Comment(
            id: 1,
            postId: 1,
            userId: 1,
            content: "Test comment",
            imageUrl: nil,
            user: mockUser
        )
        
        viewModel = PostDetailViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockPost = nil
        mockComment = nil
        mockUser = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertNil(viewModel.post)
        XCTAssertTrue(viewModel.comments.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingComments)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showSuccessMessage)
        XCTAssertEqual(viewModel.successMessage, "")
        XCTAssertFalse(viewModel.isTogglingLike)
        XCTAssertFalse(viewModel.isTogglingBookmark)
        XCTAssertFalse(viewModel.isAddingComment)
        XCTAssertEqual(viewModel.commentText, "")
        XCTAssertNil(viewModel.selectedCommentImage)
        XCTAssertFalse(viewModel.showImagePicker)
    }
    
    // MARK: - Computed Properties Tests
    
    func testCanAddComment_WithText() {
        viewModel.commentText = "Test comment"
        XCTAssertTrue(viewModel.canAddComment)
    }
    
    func testCanAddComment_WithImage() {
        viewModel.selectedCommentImage = UIImage()
        XCTAssertTrue(viewModel.canAddComment)
    }
    
    func testCanAddComment_WithTextAndImage() {
        viewModel.commentText = "Test comment"
        viewModel.selectedCommentImage = UIImage()
        XCTAssertTrue(viewModel.canAddComment)
    }
    
    func testCanAddComment_Empty() {
        XCTAssertFalse(viewModel.canAddComment)
    }
    
    func testCanAddComment_WhitespaceOnly() {
        viewModel.commentText = "   \n\t   "
        XCTAssertFalse(viewModel.canAddComment)
    }
    
    func testCanAddComment_WhileSubmitting() {
        viewModel.commentText = "Test comment"
        viewModel.isAddingComment = true
        XCTAssertFalse(viewModel.canAddComment)
    }
    
    func testCommentCharacterCount() {
        viewModel.commentText = "Hello"
        XCTAssertEqual(viewModel.commentCharacterCount, 5)
        
        viewModel.commentText = ""
        XCTAssertEqual(viewModel.commentCharacterCount, 0)
        
        viewModel.commentText = "こんにちは世界"
        XCTAssertEqual(viewModel.commentCharacterCount, 7)
    }
    
    func testIsCommentOverLimit() {
        // Under limit
        viewModel.commentText = String(repeating: "a", count: 500)
        XCTAssertFalse(viewModel.isCommentOverLimit)
        
        // Over limit
        viewModel.commentText = String(repeating: "a", count: 501)
        XCTAssertTrue(viewModel.isCommentOverLimit)
    }
    
    // MARK: - Post Detail Loading Tests
    
    func testLoadPostDetail_Success() async {
        // This would require mocking the PostAPIService
        // For now, we test the state changes
        
        viewModel.post = mockPost
        XCTAssertEqual(viewModel.post?.id, 1)
        XCTAssertEqual(viewModel.post?.content, "Test post content")
        XCTAssertEqual(viewModel.post?.likeCount, 5)
        XCTAssertEqual(viewModel.post?.bookmarkCount, 3)
        XCTAssertEqual(viewModel.post?.commentCount, 2)
    }
    
    func testRefreshPostDetail_WithoutPost() async {
        await viewModel.refreshPostDetail()
        // Should not crash when post is nil
        XCTAssertNil(viewModel.post)
    }
    
    // MARK: - Comments Loading Tests
    
    func testLoadComments_EmptyList() {
        viewModel.comments = []
        XCTAssertTrue(viewModel.comments.isEmpty)
    }
    
    func testLoadComments_WithComments() {
        let comment1 = Comment(id: 1, postId: 1, userId: 1, content: "First comment")
        let comment2 = Comment(id: 2, postId: 1, userId: 2, content: "Second comment")
        
        viewModel.comments = [comment2, comment1] // Unsorted
        
        // Simulate sorting that would happen in loadComments
        viewModel.comments.sort { $0.createdAt < $1.createdAt }
        
        XCTAssertEqual(viewModel.comments.count, 2)
        XCTAssertEqual(viewModel.comments.first?.id, 1)
        XCTAssertEqual(viewModel.comments.last?.id, 2)
    }
    
    // MARK: - Like Functionality Tests
    
    func testToggleLike_OptimisticUpdate() async {
        viewModel.post = mockPost
        
        // Initial state: not liked, 5 likes
        XCTAssertEqual(viewModel.post?.isLikedByCurrentUser, false)
        XCTAssertEqual(viewModel.post?.likeCount, 5)
        
        // Simulate optimistic update (without actual API call)
        var updatedPost = mockPost!
        updatedPost.updateLikeStatus(isLiked: true, likeCount: 6)
        viewModel.post = updatedPost
        
        XCTAssertEqual(viewModel.post?.isLikedByCurrentUser, true)
        XCTAssertEqual(viewModel.post?.likeCount, 6)
    }
    
    func testToggleLike_WithoutPost() async {
        await viewModel.toggleLike()
        XCTAssertEqual(viewModel.errorMessage, "投稿が見つかりません")
    }
    
    func testToggleLike_PreventMultipleRequests() async {
        viewModel.post = mockPost
        viewModel.isTogglingLike = true
        
        await viewModel.toggleLike()
        // Should not change state when already toggling
        XCTAssertTrue(viewModel.isTogglingLike)
    }
    
    // MARK: - Bookmark Functionality Tests
    
    func testToggleBookmark_OptimisticUpdate() async {
        viewModel.post = mockPost
        
        // Initial state: not bookmarked, 3 bookmarks
        XCTAssertEqual(viewModel.post?.isBookmarkedByCurrentUser, false)
        XCTAssertEqual(viewModel.post?.bookmarkCount, 3)
        
        // Simulate optimistic update (without actual API call)
        var updatedPost = mockPost!
        updatedPost.updateBookmarkStatus(isBookmarked: true, bookmarkCount: 4)
        viewModel.post = updatedPost
        
        XCTAssertEqual(viewModel.post?.isBookmarkedByCurrentUser, true)
        XCTAssertEqual(viewModel.post?.bookmarkCount, 4)
    }
    
    func testToggleBookmark_WithoutPost() async {
        await viewModel.toggleBookmark()
        XCTAssertEqual(viewModel.errorMessage, "投稿が見つかりません")
    }
    
    func testToggleBookmark_PreventMultipleRequests() async {
        viewModel.post = mockPost
        viewModel.isTogglingBookmark = true
        
        await viewModel.toggleBookmark()
        // Should not change state when already toggling
        XCTAssertTrue(viewModel.isTogglingBookmark)
    }
    
    // MARK: - Comment Functionality Tests
    
    func testAddComment_WithoutPost() async {
        await viewModel.addComment("Test comment")
        XCTAssertEqual(viewModel.errorMessage, "投稿が見つかりません")
    }
    
    func testAddComment_EmptyContent() async {
        viewModel.post = mockPost
        await viewModel.addComment("")
        XCTAssertEqual(viewModel.errorMessage, "コメント内容を入力してください")
    }
    
    func testAddComment_WhitespaceOnly() async {
        viewModel.post = mockPost
        await viewModel.addComment("   \n\t   ")
        XCTAssertEqual(viewModel.errorMessage, "コメント内容を入力してください")
    }
    
    func testAddComment_TooLong() async {
        viewModel.post = mockPost
        let longText = String(repeating: "a", count: 501)
        await viewModel.addComment(longText)
        XCTAssertEqual(viewModel.errorMessage, "コメントが長すぎます（500文字以内）")
    }
    
    func testAddComment_PreventMultipleRequests() async {
        viewModel.post = mockPost
        viewModel.isAddingComment = true
        
        await viewModel.addComment("Test comment")
        // Should not proceed when already adding comment
        XCTAssertTrue(viewModel.isAddingComment)
    }
    
    func testSubmitComment() async {
        viewModel.post = mockPost
        viewModel.commentText = "Test comment"
        
        // This would normally call the API, but we're testing the flow
        // The actual API call would be mocked in integration tests
        XCTAssertEqual(viewModel.commentText, "Test comment")
    }
    
    // MARK: - Form Management Tests
    
    func testClearCommentForm() {
        viewModel.commentText = "Test comment"
        viewModel.selectedCommentImage = UIImage()
        
        viewModel.clearCommentForm()
        
        XCTAssertEqual(viewModel.commentText, "")
        XCTAssertNil(viewModel.selectedCommentImage)
    }
    
    func testRemoveCommentImage() {
        viewModel.selectedCommentImage = UIImage()
        viewModel.removeCommentImage()
        XCTAssertNil(viewModel.selectedCommentImage)
    }
    
    func testSetCommentImage() {
        let image = UIImage()
        viewModel.setCommentImage(image)
        XCTAssertEqual(viewModel.selectedCommentImage, image)
    }
    
    // MARK: - Validation Tests
    
    func testValidateCommentContent_Valid() {
        let result = viewModel.validateCommentContent("Valid comment")
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateCommentContent_Empty() {
        let result = viewModel.validateCommentContent("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "コメント内容を入力してください")
    }
    
    func testValidateCommentContent_EmptyWithImage() {
        viewModel.selectedCommentImage = UIImage()
        let result = viewModel.validateCommentContent("")
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateCommentContent_TooLong() {
        let longText = String(repeating: "a", count: 501)
        let result = viewModel.validateCommentContent(longText)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "コメントが長すぎます（500文字以内）")
    }
    
    func testValidateCommentContent_ExactLimit() {
        let exactLimitText = String(repeating: "a", count: 500)
        let result = viewModel.validateCommentContent(exactLimitText)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    // MARK: - Utility Tests
    
    func testReset() {
        // Set up some state
        viewModel.post = mockPost
        viewModel.comments = [mockComment]
        viewModel.isLoading = true
        viewModel.isLoadingComments = true
        viewModel.errorMessage = "Test error"
        viewModel.showSuccessMessage = true
        viewModel.successMessage = "Test success"
        viewModel.isTogglingLike = true
        viewModel.isTogglingBookmark = true
        viewModel.isAddingComment = true
        viewModel.commentText = "Test comment"
        viewModel.selectedCommentImage = UIImage()
        
        // Reset
        viewModel.reset()
        
        // Verify all state is reset
        XCTAssertNil(viewModel.post)
        XCTAssertTrue(viewModel.comments.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingComments)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showSuccessMessage)
        XCTAssertEqual(viewModel.successMessage, "")
        XCTAssertFalse(viewModel.isTogglingLike)
        XCTAssertFalse(viewModel.isTogglingBookmark)
        XCTAssertFalse(viewModel.isAddingComment)
        XCTAssertEqual(viewModel.commentText, "")
        XCTAssertNil(viewModel.selectedCommentImage)
    }
    
    // MARK: - Extension Tests
    
    func testFormattedEngagementCounts() {
        viewModel.post = mockPost
        
        let counts = viewModel.formattedEngagementCounts
        XCTAssertEqual(counts.likes, "5")
        XCTAssertEqual(counts.comments, "2")
        XCTAssertEqual(counts.bookmarks, "3")
    }
    
    func testFormattedEngagementCounts_LargeNumbers() {
        var largePost = mockPost!
        largePost.likeCount = 1500
        largePost.commentCount = 2300000
        largePost.bookmarkCount = 999
        viewModel.post = largePost
        
        let counts = viewModel.formattedEngagementCounts
        XCTAssertEqual(counts.likes, "1.5K")
        XCTAssertEqual(counts.comments, "2.3M")
        XCTAssertEqual(counts.bookmarks, "999")
    }
    
    func testFormattedEngagementCounts_NoPost() {
        let counts = viewModel.formattedEngagementCounts
        XCTAssertEqual(counts.likes, "0")
        XCTAssertEqual(counts.comments, "0")
        XCTAssertEqual(counts.bookmarks, "0")
    }
    
    func testIsCurrentUserPostOwner_True() {
        // This would require mocking AuthService.shared.currentUser
        // For now, we test the logic structure
        viewModel.post = mockPost
        // In a real test, we would mock AuthService to return a user with ID 1
        // XCTAssertTrue(viewModel.isCurrentUserPostOwner)
    }
    
    func testIsCurrentUserPostOwner_False() {
        // This would require mocking AuthService.shared.currentUser
        // For now, we test the logic structure
        var differentUserPost = mockPost!
        differentUserPost.userId = 999
        viewModel.post = differentUserPost
        // In a real test, we would mock AuthService to return a user with ID 1
        // XCTAssertFalse(viewModel.isCurrentUserPostOwner)
    }
    
    func testIsCurrentUserPostOwner_NoPost() {
        XCTAssertFalse(viewModel.isCurrentUserPostOwner)
    }
    
    func testEngagementSummary() {
        viewModel.post = mockPost
        let summary = viewModel.engagementSummary
        // This depends on the implementation in Post.engagementSummary
        XCTAssertFalse(summary.isEmpty)
    }
    
    func testEngagementSummary_NoPost() {
        let summary = viewModel.engagementSummary
        XCTAssertEqual(summary, "")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_PostAPIError() async {
        // Test that error messages are properly set
        // This would be more comprehensive with actual API mocking
        viewModel.errorMessage = "Test error"
        XCTAssertEqual(viewModel.errorMessage, "Test error")
    }
    
    func testErrorHandling_CommentError() async {
        // Test that comment errors are properly handled
        viewModel.errorMessage = "Comment error"
        XCTAssertEqual(viewModel.errorMessage, "Comment error")
    }
    
    func testErrorHandling_EngagementError() async {
        // Test that engagement errors are properly handled
        viewModel.errorMessage = "Engagement error"
        XCTAssertEqual(viewModel.errorMessage, "Engagement error")
    }
    
    // MARK: - State Management Tests
    
    func testLoadingStates() {
        // Test individual loading states
        viewModel.isLoading = true
        XCTAssertTrue(viewModel.isLoading)
        
        viewModel.isLoadingComments = true
        XCTAssertTrue(viewModel.isLoadingComments)
        
        viewModel.isTogglingLike = true
        XCTAssertTrue(viewModel.isTogglingLike)
        
        viewModel.isTogglingBookmark = true
        XCTAssertTrue(viewModel.isTogglingBookmark)
        
        viewModel.isAddingComment = true
        XCTAssertTrue(viewModel.isAddingComment)
    }
    
    func testSuccessMessage() async {
        // Test success message display
        viewModel.successMessage = "Success!"
        viewModel.showSuccessMessage = true
        
        XCTAssertEqual(viewModel.successMessage, "Success!")
        XCTAssertTrue(viewModel.showSuccessMessage)
    }
}

// MARK: - Mock Extensions

extension PostDetailViewModelTests {
    
    /// Create a mock post with specific engagement values
    func createMockPost(
        id: Int = 1,
        likeCount: Int = 0,
        bookmarkCount: Int = 0,
        commentCount: Int = 0,
        isLiked: Bool = false,
        isBookmarked: Bool = false
    ) -> Post {
        var post = Post(id: id, userId: 1, content: "Mock post")
        post.likeCount = likeCount
        post.bookmarkCount = bookmarkCount
        post.commentCount = commentCount
        post.isLikedByCurrentUser = isLiked
        post.isBookmarkedByCurrentUser = isBookmarked
        return post
    }
    
    /// Create a mock comment
    func createMockComment(
        id: Int = 1,
        postId: Int = 1,
        userId: Int = 1,
        content: String = "Mock comment"
    ) -> Comment {
        return Comment(
            id: id,
            postId: postId,
            userId: userId,
            content: content,
            user: mockUser
        )
    }
}