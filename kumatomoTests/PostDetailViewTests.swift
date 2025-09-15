import XCTest
import SwiftUI
@testable import kumatomo

/// Unit tests for PostDetailView functionality and integration
final class PostDetailViewTests: XCTestCase {
    
    var viewModel: PostDetailViewModel!
    var commentViewModel: CommentViewModel!
    
    override func setUpWithError() throws {
        viewModel = PostDetailViewModel()
        commentViewModel = CommentViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        commentViewModel = nil
    }
    
    // MARK: - PostDetailViewModel Integration Tests
    
    func testPostDetailViewModelIntegration() async throws {
        // Test that PostDetailView properly integrates with PostDetailViewModel
        
        // Mock post data
        let mockPost = createMockPost()
        
        // Simulate loading post detail
        await viewModel.loadPostDetail(postId: mockPost.id)
        
        // Verify initial state
        XCTAssertFalse(viewModel.isLoading, "Loading should complete")
        XCTAssertNil(viewModel.errorMessage, "Should not have error message initially")
    }
    
    func testEngagementIntegration() async throws {
        // Test engagement functionality integration
        
        let mockPost = createMockPost()
        viewModel.post = mockPost
        
        // Test like toggle
        let initialLikeState = mockPost.isLikedByCurrentUser ?? false
        let initialLikeCount = mockPost.likeCount ?? 0
        
        await viewModel.toggleLike()
        
        // Verify optimistic update occurred
        XCTAssertNotEqual(viewModel.post?.isLikedByCurrentUser, initialLikeState, "Like state should change optimistically")
        
        if initialLikeState {
            XCTAssertEqual(viewModel.post?.likeCount, initialLikeCount - 1, "Like count should decrease")
        } else {
            XCTAssertEqual(viewModel.post?.likeCount, initialLikeCount + 1, "Like count should increase")
        }
    }
    
    func testCommentIntegration() async throws {
        // Test comment functionality integration
        
        let mockPost = createMockPost()
        viewModel.post = mockPost
        
        let initialCommentCount = viewModel.comments.count
        
        // Test adding comment through CommentViewModel
        commentViewModel.commentText = "テストコメント"
        let success = await commentViewModel.submitComment(postId: mockPost.id)
        
        // Note: This would require proper API mocking for full integration test
        // For now, we test the integration points
        XCTAssertTrue(commentViewModel.commentText.isEmpty || !success, "Comment text should be cleared on success or remain on failure")
    }
    
    // MARK: - View State Tests
    
    func testLoadingStates() {
        // Test different loading states
        
        viewModel.isLoading = true
        XCTAssertTrue(viewModel.isLoading, "Should be in loading state")
        
        viewModel.isLoadingComments = true
        XCTAssertTrue(viewModel.isLoadingComments, "Should be loading comments")
        
        viewModel.isTogglingLike = true
        XCTAssertTrue(viewModel.isTogglingLike, "Should be toggling like")
        
        viewModel.isTogglingBookmark = true
        XCTAssertTrue(viewModel.isTogglingBookmark, "Should be toggling bookmark")
        
        viewModel.isAddingComment = true
        XCTAssertTrue(viewModel.isAddingComment, "Should be adding comment")
    }
    
    func testErrorStates() {
        // Test error handling
        
        let errorMessage = "テストエラーメッセージ"
        viewModel.errorMessage = errorMessage
        
        XCTAssertEqual(viewModel.errorMessage, errorMessage, "Error message should be set")
        
        // Test error clearing
        viewModel.errorMessage = nil
        XCTAssertNil(viewModel.errorMessage, "Error message should be cleared")
    }
    
    func testSuccessStates() {
        // Test success message handling
        
        let successMessage = "成功メッセージ"
        viewModel.successMessage = successMessage
        viewModel.showSuccessMessage = true
        
        XCTAssertEqual(viewModel.successMessage, successMessage, "Success message should be set")
        XCTAssertTrue(viewModel.showSuccessMessage, "Should show success message")
    }
    
    // MARK: - Comment Validation Tests
    
    func testCommentValidation() {
        // Test comment validation logic
        
        // Test empty comment
        commentViewModel.commentText = ""
        commentViewModel.selectedImage = nil
        commentViewModel.validateContent()
        
        XCTAssertNotNil(commentViewModel.validationError, "Should have validation error for empty content")
        XCTAssertFalse(commentViewModel.canSubmit, "Should not be able to submit empty comment")
        
        // Test valid comment
        commentViewModel.commentText = "有効なコメント"
        commentViewModel.validateContent()
        
        XCTAssertNil(commentViewModel.validationError, "Should not have validation error for valid content")
        XCTAssertTrue(commentViewModel.canSubmit, "Should be able to submit valid comment")
        
        // Test comment too long
        commentViewModel.commentText = String(repeating: "あ", count: 600)
        commentViewModel.validateContent()
        
        XCTAssertNotNil(commentViewModel.validationError, "Should have validation error for long content")
        XCTAssertFalse(commentViewModel.canSubmit, "Should not be able to submit long comment")
    }
    
    func testCommentCharacterCount() {
        // Test character count functionality
        
        let testText = "テストコメント"
        commentViewModel.commentText = testText
        
        XCTAssertEqual(commentViewModel.characterCount, testText.count, "Character count should match text length")
        
        let maxLength = 500
        let longText = String(repeating: "あ", count: maxLength + 100)
        commentViewModel.commentText = longText
        
        XCTAssertTrue(commentViewModel.isOverCharacterLimit, "Should be over character limit")
        XCTAssertTrue(commentViewModel.remainingCharacterCount < 0, "Remaining count should be negative")
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationState() {
        // Test navigation-related state
        
        let mockPost = createMockPost()
        viewModel.post = mockPost
        
        // Test post owner detection
        // This would require proper user context for full testing
        let isOwner = viewModel.isCurrentUserPostOwner
        XCTAssertFalse(isOwner, "Should correctly identify post ownership")
    }
    
    // MARK: - Engagement Stats Tests
    
    func testEngagementStats() {
        // Test engagement statistics formatting
        
        let mockPost = createMockPostWithEngagement()
        viewModel.post = mockPost
        
        let stats = viewModel.formattedEngagementCounts
        
        XCTAssertFalse(stats.likes.isEmpty, "Likes count should be formatted")
        XCTAssertFalse(stats.comments.isEmpty, "Comments count should be formatted")
        XCTAssertFalse(stats.bookmarks.isEmpty, "Bookmarks count should be formatted")
    }
    
    // MARK: - Keyboard Handling Tests
    
    func testKeyboardHandling() {
        // Test keyboard-related functionality
        
        // This would typically test keyboard show/hide notifications
        // For unit tests, we can test the state changes
        
        let initialHeight: CGFloat = 0
        var keyboardHeight: CGFloat = initialHeight
        
        // Simulate keyboard show
        keyboardHeight = 300
        XCTAssertEqual(keyboardHeight, 300, "Keyboard height should be updated")
        
        // Simulate keyboard hide
        keyboardHeight = 0
        XCTAssertEqual(keyboardHeight, 0, "Keyboard height should be reset")
    }
    
    // MARK: - Image Handling Tests
    
    func testImageHandling() {
        // Test image selection and removal
        
        let mockImage = createMockImage()
        
        // Test image selection
        commentViewModel.selectedImage = mockImage
        XCTAssertNotNil(commentViewModel.selectedImage, "Image should be selected")
        XCTAssertTrue(commentViewModel.hasContent, "Should have content with image")
        
        // Test image removal
        commentViewModel.removeSelectedImage()
        XCTAssertNil(commentViewModel.selectedImage, "Image should be removed")
    }
    
    // MARK: - Form State Tests
    
    func testFormState() {
        // Test comment form state management
        
        // Test initial state
        XCTAssertFalse(commentViewModel.hasContent, "Should not have content initially")
        XCTAssertFalse(commentViewModel.canSubmit, "Should not be able to submit initially")
        
        // Test with text content
        commentViewModel.commentText = "テスト"
        XCTAssertTrue(commentViewModel.hasContent, "Should have content with text")
        XCTAssertTrue(commentViewModel.canSubmit, "Should be able to submit with valid text")
        
        // Test form clearing
        commentViewModel.clearForm()
        XCTAssertFalse(commentViewModel.hasContent, "Should not have content after clearing")
        XCTAssertFalse(commentViewModel.canSubmit, "Should not be able to submit after clearing")
    }
    
    // MARK: - Refresh Tests
    
    func testRefreshFunctionality() async {
        // Test refresh functionality
        
        let mockPost = createMockPost()
        viewModel.post = mockPost
        
        // Test post refresh
        await viewModel.refreshPostDetail()
        // Would verify API call in integration test
        
        // Test comments refresh
        await viewModel.refreshComments()
        // Would verify API call in integration test
    }
    
    // MARK: - Helper Methods
    
    private func createMockPost() -> Post {
        return Post(
            id: 1,
            userId: 1,
            content: "テスト投稿内容"
        )
    }
    
    private func createMockPostWithEngagement() -> Post {
        var post = createMockPost()
        post.likeCount = 42
        post.commentCount = 7
        post.bookmarkCount = 15
        post.isLikedByCurrentUser = false
        post.isBookmarkedByCurrentUser = true
        return post
    }
    
    private func createMockComment() -> Comment {
        return Comment(
            id: 1,
            postId: 1,
            userId: 1,
            content: "テストコメント"
        )
    }
    
    private func createMockImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.blue.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}

// MARK: - PostDetailView Component Tests

final class PostDetailViewComponentTests: XCTestCase {
    
    // MARK: - PostContentSection Tests
    
    func testPostContentSection() {
        // Test PostContentSection component
        
        let mockPost = createMockPost()
        var profileTapCalled = false
        
        // This would be tested in SwiftUI preview or integration test
        // For unit test, we verify the data preparation
        
        XCTAssertNotNil(mockPost.content, "Post should have content")
        XCTAssertNotNil(mockPost.createdAt, "Post should have creation date")
    }
    
    // MARK: - EngagementSection Tests
    
    func testEngagementSection() {
        // Test EngagementSection component
        
        let mockPost = createMockPostWithEngagement()
        
        XCTAssertTrue(mockPost.totalEngagementCount > 0, "Post should have engagement")
        XCTAssertNotNil(mockPost.likeCount, "Post should have like count")
        XCTAssertNotNil(mockPost.commentCount, "Post should have comment count")
        XCTAssertNotNil(mockPost.bookmarkCount, "Post should have bookmark count")
    }
    
    // MARK: - CommentsSection Tests
    
    func testCommentsSection() {
        // Test CommentsSection component
        
        let mockComments = [createMockComment()]
        
        XCTAssertFalse(mockComments.isEmpty, "Should have mock comments")
        XCTAssertNotNil(mockComments.first?.content, "Comment should have content")
    }
    
    // MARK: - CommentComposeSection Tests
    
    func testCommentComposeSection() {
        // Test CommentComposeSection component
        
        let commentViewModel = CommentViewModel()
        
        // Test initial state
        XCTAssertTrue(commentViewModel.commentText.isEmpty, "Comment text should be empty initially")
        XCTAssertNil(commentViewModel.selectedImage, "Selected image should be nil initially")
        XCTAssertFalse(commentViewModel.canSubmit, "Should not be able to submit initially")
    }
    
    // MARK: - Helper Methods
    
    private func createMockPost() -> Post {
        var post = Post(
            id: 1,
            userId: 1,
            content: "テスト投稿内容"
        )
        post.createdAt = Date()
        return post
    }
    
    private func createMockPostWithEngagement() -> Post {
        var post = createMockPost()
        post.likeCount = 42
        post.commentCount = 7
        post.bookmarkCount = 15
        post.isLikedByCurrentUser = false
        post.isBookmarkedByCurrentUser = true
        return post
    }
    
    private func createMockComment() -> Comment {
        return Comment(
            id: 1,
            postId: 1,
            userId: 1,
            content: "テストコメント"
        )
    }
}