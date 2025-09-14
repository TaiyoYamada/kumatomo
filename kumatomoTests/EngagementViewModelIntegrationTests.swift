import XCTest
@testable import kumatomo

@MainActor
class EngagementViewModelIntegrationTests: XCTestCase {
    
    var viewModel: EngagementViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = EngagementViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    func testEngagementViewModelIntegrationWithServices() async {
        // Test that the ViewModel can be instantiated and has proper service dependencies
        XCTAssertNotNil(viewModel)
        
        // Test initial state
        XCTAssertTrue(viewModel.likedPosts.isEmpty)
        XCTAssertTrue(viewModel.bookmarkedPosts.isEmpty)
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
        XCTAssertFalse(viewModel.isLoadingBookmarkedPosts)
        
        // Test that methods can be called without crashing
        // Note: These will likely fail due to network/auth issues in test environment,
        // but they should not crash
        do {
            await viewModel.loadLikedPosts()
            await viewModel.loadBookmarkedPosts()
        } catch {
            // Expected to fail in test environment, but should not crash
            print("Expected network failure in test environment: \(error)")
        }
        
        // Verify state after attempted loads
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
        XCTAssertFalse(viewModel.isLoadingBookmarkedPosts)
    }
    
    func testEngagementViewModelStateManagement() async {
        // Test state management with mock data
        let mockPost = createMockPost(id: 1, likeCount: 5, isLiked: false)
        
        // Add post to collections
        viewModel.likedPosts = [mockPost]
        viewModel.bookmarkedPosts = [mockPost]
        
        // Test utility methods
        XCTAssertNotNil(viewModel.getPost(byId: 1))
        XCTAssertNil(viewModel.getPost(byId: 999))
        
        // Test removal
        viewModel.removePost(withId: 1)
        XCTAssertTrue(viewModel.likedPosts.isEmpty)
        XCTAssertTrue(viewModel.bookmarkedPosts.isEmpty)
    }
    
    func testEngagementViewModelErrorHandling() async {
        // Test that error handling doesn't crash the app
        let mockPost = createMockPost(id: 1)
        
        // These operations will likely fail in test environment
        // but should handle errors gracefully
        await viewModel.toggleLike(for: mockPost)
        await viewModel.toggleBookmark(for: mockPost)
        
        // Verify that the ViewModel is still in a valid state
        XCTAssertFalse(viewModel.isLiking(postId: 1))
        XCTAssertFalse(viewModel.isBookmarking(postId: 1))
    }
    
    func testEngagementViewModelReset() {
        // Set up some state
        viewModel.likedPosts = [createMockPost(id: 1)]
        viewModel.bookmarkedPosts = [createMockPost(id: 2)]
        viewModel.isLoadingLikedPosts = true
        viewModel.errorMessage = "Test error"
        
        // Reset
        viewModel.reset()
        
        // Verify clean state
        XCTAssertTrue(viewModel.likedPosts.isEmpty)
        XCTAssertTrue(viewModel.bookmarkedPosts.isEmpty)
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.likedPostsPage, 1)
        XCTAssertEqual(viewModel.bookmarkedPostsPage, 1)
    }
    
    func testEngagementViewModelFormattingMethods() {
        // Test formatting with various counts
        viewModel.likedPosts = Array(1...1234).map { createMockPost(id: $0) }
        viewModel.bookmarkedPosts = Array(1...567).map { createMockPost(id: $0 + 2000) }
        
        let formatted = viewModel.formattedCounts
        XCTAssertEqual(formatted.likedPosts, "1.2K")
        XCTAssertEqual(formatted.bookmarkedPosts, "567")
        
        let summary = viewModel.engagementSummary
        XCTAssertTrue(summary.contains("1234件のいいね"))
        XCTAssertTrue(summary.contains("567件のブックマーク"))
        
        XCTAssertEqual(viewModel.totalEngagementCount, 1801)
        XCTAssertFalse(viewModel.hasNoEngagement)
    }
    
    func testEngagementViewModelPaginationLogic() async {
        // Test pagination state management
        XCTAssertEqual(viewModel.likedPostsPage, 1)
        XCTAssertEqual(viewModel.bookmarkedPostsPage, 1)
        XCTAssertTrue(viewModel.hasMoreLikedPosts)
        XCTAssertTrue(viewModel.hasMoreBookmarkedPosts)
        
        // Test load more when no more available
        viewModel.hasMoreLikedPosts = false
        viewModel.hasMoreBookmarkedPosts = false
        
        await viewModel.loadMoreLikedPosts()
        await viewModel.loadMoreBookmarkedPosts()
        
        // Should not have changed loading state since no more available
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
        XCTAssertFalse(viewModel.isLoadingBookmarkedPosts)
    }
    
    func testEngagementViewModelConcurrentOperations() async {
        let post = createMockPost(id: 1)
        
        // Test that concurrent operations are handled properly
        async let task1 = viewModel.toggleLike(for: post)
        async let task2 = viewModel.toggleBookmark(for: post)
        async let task3 = viewModel.loadLikedPosts()
        async let task4 = viewModel.loadBookmarkedPosts()
        
        // Wait for all operations to complete
        await task1
        await task2
        await task3
        await task4
        
        // Verify final state is consistent
        XCTAssertFalse(viewModel.isLiking(postId: 1))
        XCTAssertFalse(viewModel.isBookmarking(postId: 1))
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
        XCTAssertFalse(viewModel.isLoadingBookmarkedPosts)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPost(
        id: Int,
        likeCount: Int = 0,
        bookmarkCount: Int = 0,
        commentCount: Int = 0,
        isLiked: Bool = false,
        isBookmarked: Bool = false
    ) -> Post {
        var post = Post(id: id, userId: 1, content: "Test post \(id)")
        post.likeCount = likeCount
        post.bookmarkCount = bookmarkCount
        post.commentCount = commentCount
        post.isLikedByCurrentUser = isLiked
        post.isBookmarkedByCurrentUser = isBookmarked
        return post
    }
}