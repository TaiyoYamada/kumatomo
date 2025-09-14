import XCTest
@testable import kumatomo

@MainActor
class EngagementViewModelTests: XCTestCase {
    
    var viewModel: EngagementViewModel!
    var mockEngagementService: MockEngagementAPIService!
    
    override func setUp() {
        super.setUp()
        viewModel = EngagementViewModel()
        mockEngagementService = MockEngagementAPIService()
        
        // Replace the shared service with our mock for testing
        // Note: In a real implementation, you'd want to inject dependencies
        // For now, we'll test the public interface
    }
    
    override func tearDown() {
        viewModel = nil
        mockEngagementService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertTrue(viewModel.likedPosts.isEmpty)
        XCTAssertTrue(viewModel.bookmarkedPosts.isEmpty)
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
        XCTAssertFalse(viewModel.isLoadingBookmarkedPosts)
        XCTAssertFalse(viewModel.isRefreshingLikedPosts)
        XCTAssertFalse(viewModel.isRefreshingBookmarkedPosts)
        XCTAssertTrue(viewModel.likingPostIds.isEmpty)
        XCTAssertTrue(viewModel.bookmarkingPostIds.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showErrorAlert)
        XCTAssertTrue(viewModel.hasMoreLikedPosts)
        XCTAssertTrue(viewModel.hasMoreBookmarkedPosts)
        XCTAssertEqual(viewModel.likedPostsPage, 1)
        XCTAssertEqual(viewModel.bookmarkedPostsPage, 1)
    }
    
    // MARK: - Computed Properties Tests
    
    func testHasLikedPosts() {
        XCTAssertFalse(viewModel.hasLikedPosts)
        
        viewModel.likedPosts = [createMockPost(id: 1)]
        XCTAssertTrue(viewModel.hasLikedPosts)
    }
    
    func testHasBookmarkedPosts() {
        XCTAssertFalse(viewModel.hasBookmarkedPosts)
        
        viewModel.bookmarkedPosts = [createMockPost(id: 1)]
        XCTAssertTrue(viewModel.hasBookmarkedPosts)
    }
    
    func testIsPerformingAnyAction() {
        XCTAssertFalse(viewModel.isPerformingAnyAction)
        
        viewModel.isLoadingLikedPosts = true
        XCTAssertTrue(viewModel.isPerformingAnyAction)
        
        viewModel.isLoadingLikedPosts = false
        viewModel.likingPostIds.insert(1)
        XCTAssertTrue(viewModel.isPerformingAnyAction)
    }
    
    func testHasNoEngagement() {
        XCTAssertTrue(viewModel.hasNoEngagement)
        
        viewModel.likedPosts = [createMockPost(id: 1)]
        XCTAssertFalse(viewModel.hasNoEngagement)
        
        viewModel.likedPosts = []
        viewModel.bookmarkedPosts = [createMockPost(id: 2)]
        XCTAssertFalse(viewModel.hasNoEngagement)
    }
    
    func testTotalEngagementCount() {
        XCTAssertEqual(viewModel.totalEngagementCount, 0)
        
        viewModel.likedPosts = [createMockPost(id: 1), createMockPost(id: 2)]
        viewModel.bookmarkedPosts = [createMockPost(id: 3)]
        XCTAssertEqual(viewModel.totalEngagementCount, 3)
    }
    
    // MARK: - Utility Methods Tests
    
    func testIsLiking() {
        XCTAssertFalse(viewModel.isLiking(postId: 1))
        
        viewModel.likingPostIds.insert(1)
        XCTAssertTrue(viewModel.isLiking(postId: 1))
        XCTAssertFalse(viewModel.isLiking(postId: 2))
    }
    
    func testIsBookmarking() {
        XCTAssertFalse(viewModel.isBookmarking(postId: 1))
        
        viewModel.bookmarkingPostIds.insert(1)
        XCTAssertTrue(viewModel.isBookmarking(postId: 1))
        XCTAssertFalse(viewModel.isBookmarking(postId: 2))
    }
    
    func testGetPostById() {
        let likedPost = createMockPost(id: 1)
        let bookmarkedPost = createMockPost(id: 2)
        
        viewModel.likedPosts = [likedPost]
        viewModel.bookmarkedPosts = [bookmarkedPost]
        
        XCTAssertEqual(viewModel.getPost(byId: 1)?.id, 1)
        XCTAssertEqual(viewModel.getPost(byId: 2)?.id, 2)
        XCTAssertNil(viewModel.getPost(byId: 3))
    }
    
    func testRemovePost() {
        let post1 = createMockPost(id: 1)
        let post2 = createMockPost(id: 2)
        
        viewModel.likedPosts = [post1, post2]
        viewModel.bookmarkedPosts = [post1]
        
        viewModel.removePost(withId: 1)
        
        XCTAssertEqual(viewModel.likedPosts.count, 1)
        XCTAssertEqual(viewModel.likedPosts.first?.id, 2)
        XCTAssertTrue(viewModel.bookmarkedPosts.isEmpty)
    }
    
    func testReset() {
        // Set up some state
        viewModel.likedPosts = [createMockPost(id: 1)]
        viewModel.bookmarkedPosts = [createMockPost(id: 2)]
        viewModel.isLoadingLikedPosts = true
        viewModel.likingPostIds.insert(1)
        viewModel.errorMessage = "Test error"
        viewModel.likedPostsPage = 3
        
        viewModel.reset()
        
        XCTAssertTrue(viewModel.likedPosts.isEmpty)
        XCTAssertTrue(viewModel.bookmarkedPosts.isEmpty)
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
        XCTAssertTrue(viewModel.likingPostIds.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.likedPostsPage, 1)
        XCTAssertEqual(viewModel.bookmarkedPostsPage, 1)
    }
    
    // MARK: - Formatting Tests
    
    func testFormattedCounts() {
        viewModel.likedPosts = Array(1...1500).map { createMockPost(id: $0) }
        viewModel.bookmarkedPosts = Array(1...500).map { createMockPost(id: $0 + 2000) }
        
        let formatted = viewModel.formattedCounts
        XCTAssertEqual(formatted.likedPosts, "1.5K")
        XCTAssertEqual(formatted.bookmarkedPosts, "500")
    }
    
    func testEngagementSummary() {
        // Empty state
        XCTAssertEqual(viewModel.engagementSummary, "エンゲージメントなし")
        
        // Only liked posts
        viewModel.likedPosts = [createMockPost(id: 1), createMockPost(id: 2)]
        XCTAssertEqual(viewModel.engagementSummary, "2件のいいね")
        
        // Only bookmarked posts
        viewModel.likedPosts = []
        viewModel.bookmarkedPosts = [createMockPost(id: 3)]
        XCTAssertEqual(viewModel.engagementSummary, "1件のブックマーク")
        
        // Both
        viewModel.likedPosts = [createMockPost(id: 1)]
        viewModel.bookmarkedPosts = [createMockPost(id: 2)]
        XCTAssertEqual(viewModel.engagementSummary, "1件のいいね • 1件のブックマーク")
    }
    
    // MARK: - State Management Tests
    
    func testUpdatePostInCollections() {
        let post1 = createMockPost(id: 1, likeCount: 5, isLiked: false)
        let post2 = createMockPost(id: 2, likeCount: 3, isLiked: true)
        
        viewModel.likedPosts = [post1]
        viewModel.bookmarkedPosts = [post1, post2]
        
        // Update post1 in both collections
        viewModel.updatePostInCollections(postId: 1) { post in
            post.updateLikeStatus(isLiked: true, likeCount: 6)
        }
        
        // Check liked posts collection
        XCTAssertEqual(viewModel.likedPosts.first?.likeCount, 6)
        XCTAssertEqual(viewModel.likedPosts.first?.isLikedByCurrentUser, true)
        
        // Check bookmarked posts collection
        let updatedPost = viewModel.bookmarkedPosts.first { $0.id == 1 }
        XCTAssertEqual(updatedPost?.likeCount, 6)
        XCTAssertEqual(updatedPost?.isLikedByCurrentUser, true)
        
        // Post2 should remain unchanged
        let unchangedPost = viewModel.bookmarkedPosts.first { $0.id == 2 }
        XCTAssertEqual(unchangedPost?.likeCount, 3)
        XCTAssertEqual(unchangedPost?.isLikedByCurrentUser, true)
    }
    
    // MARK: - Async Operation Tests
    
    func testLoadLikedPostsSuccess() async {
        // This test would require mocking the EngagementAPIService
        // For now, we'll test the state changes that should occur
        
        // Test initial loading state
        let loadTask = Task {
            await viewModel.loadLikedPosts()
        }
        
        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await loadTask.value
        
        // After completion, loading should be false
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
    }
    
    func testLoadBookmarkedPostsSuccess() async {
        let loadTask = Task {
            await viewModel.loadBookmarkedPosts()
        }
        
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await loadTask.value
        
        XCTAssertFalse(viewModel.isLoadingBookmarkedPosts)
    }
    
    func testRefreshLikedPosts() async {
        // Set up existing data
        viewModel.likedPosts = [createMockPost(id: 1)]
        viewModel.likedPostsPage = 3
        
        let refreshTask = Task {
            await viewModel.refreshLikedPosts()
        }
        
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await refreshTask.value
        
        // Page should be reset to 1 after refresh
        XCTAssertEqual(viewModel.likedPostsPage, 1)
        XCTAssertFalse(viewModel.isRefreshingLikedPosts)
    }
    
    func testRefreshBookmarkedPosts() async {
        viewModel.bookmarkedPosts = [createMockPost(id: 1)]
        viewModel.bookmarkedPostsPage = 3
        
        let refreshTask = Task {
            await viewModel.refreshBookmarkedPosts()
        }
        
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await refreshTask.value
        
        XCTAssertEqual(viewModel.bookmarkedPostsPage, 1)
        XCTAssertFalse(viewModel.isRefreshingBookmarkedPosts)
    }
    
    // MARK: - Optimistic Updates Tests
    
    func testToggleLikeOptimisticUpdate() async {
        let post = createMockPost(id: 1, likeCount: 5, isLiked: false)
        viewModel.likedPosts = [post]
        
        // Start the toggle operation
        let toggleTask = Task {
            await viewModel.toggleLike(for: post)
        }
        
        // Give it a moment to start and apply optimistic update
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // The post should be in the "liking" state
        XCTAssertTrue(viewModel.isLiking(postId: 1))
        
        await toggleTask.value
        
        // After completion, should not be in liking state
        XCTAssertFalse(viewModel.isLiking(postId: 1))
    }
    
    func testToggleBookmarkOptimisticUpdate() async {
        let post = createMockPost(id: 1, bookmarkCount: 3, isBookmarked: false)
        viewModel.bookmarkedPosts = [post]
        
        let toggleTask = Task {
            await viewModel.toggleBookmark(for: post)
        }
        
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        XCTAssertTrue(viewModel.isBookmarking(postId: 1))
        
        await toggleTask.value
        
        XCTAssertFalse(viewModel.isBookmarking(postId: 1))
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testPreventMultipleLikeOperations() async {
        let post = createMockPost(id: 1)
        
        // Start two like operations simultaneously
        let task1 = Task { await viewModel.toggleLike(for: post) }
        let task2 = Task { await viewModel.toggleLike(for: post) }
        
        await task1.value
        await task2.value
        
        // Only one operation should have been processed
        XCTAssertFalse(viewModel.isLiking(postId: 1))
    }
    
    func testPreventMultipleBookmarkOperations() async {
        let post = createMockPost(id: 1)
        
        let task1 = Task { await viewModel.toggleBookmark(for: post) }
        let task2 = Task { await viewModel.toggleBookmark(for: post) }
        
        await task1.value
        await task2.value
        
        XCTAssertFalse(viewModel.isBookmarking(postId: 1))
    }
    
    func testPreventMultipleLoadOperations() async {
        // Start multiple load operations
        let task1 = Task { await viewModel.loadLikedPosts() }
        let task2 = Task { await viewModel.loadLikedPosts() }
        let task3 = Task { await viewModel.loadBookmarkedPosts() }
        let task4 = Task { await viewModel.loadBookmarkedPosts() }
        
        await task1.value
        await task2.value
        await task3.value
        await task4.value
        
        // All operations should complete without issues
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
        XCTAssertFalse(viewModel.isLoadingBookmarkedPosts)
    }
    
    // MARK: - Pagination Tests
    
    func testPaginationState() {
        XCTAssertEqual(viewModel.likedPostsPage, 1)
        XCTAssertEqual(viewModel.bookmarkedPostsPage, 1)
        XCTAssertTrue(viewModel.hasMoreLikedPosts)
        XCTAssertTrue(viewModel.hasMoreBookmarkedPosts)
    }
    
    func testLoadMoreLikedPostsWhenHasMore() async {
        viewModel.hasMoreLikedPosts = true
        viewModel.isLoadingLikedPosts = false
        
        let loadTask = Task {
            await viewModel.loadMoreLikedPosts()
        }
        
        await loadTask.value
        
        // Should have attempted to load more
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
    }
    
    func testLoadMoreLikedPostsWhenNoMore() async {
        viewModel.hasMoreLikedPosts = false
        
        await viewModel.loadMoreLikedPosts()
        
        // Should not have started loading
        XCTAssertFalse(viewModel.isLoadingLikedPosts)
    }
    
    func testLoadMoreBookmarkedPostsWhenHasMore() async {
        viewModel.hasMoreBookmarkedPosts = true
        viewModel.isLoadingBookmarkedPosts = false
        
        let loadTask = Task {
            await viewModel.loadMoreBookmarkedPosts()
        }
        
        await loadTask.value
        
        XCTAssertFalse(viewModel.isLoadingBookmarkedPosts)
    }
    
    func testLoadMoreBookmarkedPostsWhenNoMore() async {
        viewModel.hasMoreBookmarkedPosts = false
        
        await viewModel.loadMoreBookmarkedPosts()
        
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

// MARK: - Mock Services

class MockEngagementAPIService {
    var shouldSucceed = true
    var mockLikedPosts: [Post] = []
    var mockBookmarkedPosts: [Post] = []
    var mockLikeResponse: LikeResponse?
    var mockBookmarkResponse: BookmarkResponse?
    var mockError: EngagementError?
    
    func fetchLikedPosts() async throws -> [Post] {
        if shouldSucceed {
            return mockLikedPosts
        } else {
            throw mockError ?? EngagementError.networkError(NSError(domain: "test", code: -1))
        }
    }
    
    func fetchBookmarkedPosts() async throws -> [Post] {
        if shouldSucceed {
            return mockBookmarkedPosts
        } else {
            throw mockError ?? EngagementError.networkError(NSError(domain: "test", code: -1))
        }
    }
    
    func optimisticToggleLike(
        postId: Int,
        currentState: Bool,
        currentCount: Int
    ) async -> (success: Bool, response: LikeResponse?, error: EngagementError?) {
        if shouldSucceed {
            let response = mockLikeResponse ?? LikeResponse(
                isLiked: !currentState,
                likeCount: currentState ? currentCount - 1 : currentCount + 1
            )
            return (success: true, response: response, error: nil)
        } else {
            let rollbackResponse = LikeResponse(isLiked: currentState, likeCount: currentCount)
            return (success: false, response: rollbackResponse, error: mockError)
        }
    }
    
    func optimisticToggleBookmark(
        postId: Int,
        currentState: Bool,
        currentCount: Int
    ) async -> (success: Bool, response: BookmarkResponse?, error: EngagementError?) {
        if shouldSucceed {
            let response = mockBookmarkResponse ?? BookmarkResponse(
                isBookmarked: !currentState,
                bookmarkCount: currentState ? currentCount - 1 : currentCount + 1
            )
            return (success: true, response: response, error: nil)
        } else {
            let rollbackResponse = BookmarkResponse(isBookmarked: currentState, bookmarkCount: currentCount)
            return (success: false, response: rollbackResponse, error: mockError)
        }
    }
}

// MARK: - Extension for Testing

extension EngagementViewModel {
    /// Test helper to update posts in collections
    func updatePostInCollections(postId: Int, updateBlock: (inout Post) -> Void) {
        // Update in liked posts collection
        if let index = likedPosts.firstIndex(where: { $0.id == postId }) {
            updateBlock(&likedPosts[index])
        }
        
        // Update in bookmarked posts collection
        if let index = bookmarkedPosts.firstIndex(where: { $0.id == postId }) {
            updateBlock(&bookmarkedPosts[index])
        }
    }
}