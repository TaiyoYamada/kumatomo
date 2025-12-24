import Factory
@testable import kumatomo
import Mockable
import Testing

// MARK: - EngagementViewModelTests

/// エンゲージメントViewModelのテスト
@Suite("EngagementViewModel Tests")
@MainActor
struct EngagementViewModelTests {
    @Test("初期状態では空のリスト")
    func initialStateShouldBeEmpty() async {
        // Given
        let sut = EngagementViewModel()

        // Then
        #expect(sut.likedPosts.isEmpty)
        #expect(sut.bookmarkedPosts.isEmpty)
        #expect(sut.isLoadingLikedPosts == false)
        #expect(sut.isLoadingBookmarkedPosts == false)
    }

    @Test("hasLikedPostsは空でfalse")
    func hasLikedPostsShouldBeFalseWhenEmpty() async {
        // Given
        let sut = EngagementViewModel()

        // Then
        #expect(sut.hasLikedPosts == false)
    }

    @Test("hasBookmarkedPostsは空でfalse")
    func hasBookmarkedPostsShouldBeFalseWhenEmpty() async {
        // Given
        let sut = EngagementViewModel()

        // Then
        #expect(sut.hasBookmarkedPosts == false)
    }

    @Test("isPerformingAnyActionは初期状態でfalse")
    func isPerformingAnyActionShouldBeFalseInitially() async {
        // Given
        let sut = EngagementViewModel()

        // Then
        #expect(sut.isPerformingAnyAction == false)
    }

    @Test("isLikingで処理中かどうか確認できる")
    func isLikingShouldTrackInProgress() async {
        // Given
        let sut = EngagementViewModel()

        // When
        sut.likingPostIds.insert(1)

        // Then
        #expect(sut.isLiking(postId: 1) == true)
        #expect(sut.isLiking(postId: 2) == false)
    }

    @Test("isBookmarkingで処理中かどうか確認できる")
    func isBookmarkingShouldTrackInProgress() async {
        // Given
        let sut = EngagementViewModel()

        // When
        sut.bookmarkingPostIds.insert(1)

        // Then
        #expect(sut.isBookmarking(postId: 1) == true)
        #expect(sut.isBookmarking(postId: 2) == false)
    }

    @Test("resetで全てクリアされる")
    func resetShouldClearEverything() async {
        // Given
        let sut = EngagementViewModel()
        sut.likedPosts = PostFixtures.samplePosts
        sut.bookmarkedPosts = PostFixtures.samplePosts
        sut.isLoadingLikedPosts = true
        sut.likingPostIds.insert(1)

        // When
        sut.reset()

        // Then
        #expect(sut.likedPosts.isEmpty)
        #expect(sut.bookmarkedPosts.isEmpty)
        #expect(sut.isLoadingLikedPosts == false)
        #expect(sut.likingPostIds.isEmpty)
        #expect(sut.likedPostsPage == 1)
        #expect(sut.hasMoreLikedPosts == true)
    }

    @Test("hasNoEngagementは両方空でtrue")
    func hasNoEngagementShouldBeTrueWhenBothEmpty() async {
        // Given
        let sut = EngagementViewModel()

        // Then
        #expect(sut.hasNoEngagement == true)
    }

    @Test("totalEngagementCountが正確")
    func totalEngagementCountShouldBeAccurate() async {
        // Given
        let sut = EngagementViewModel()
        sut.likedPosts = [PostFixtures.createPost(id: 1), PostFixtures.createPost(id: 2)]
        sut.bookmarkedPosts = [PostFixtures.createPost(id: 3)]

        // Then
        #expect(sut.totalEngagementCount == 3)
    }

    @Test("engagementSummaryが正確に生成される")
    func engagementSummaryShouldBeAccurate() async {
        // Given
        let sut = EngagementViewModel()
        sut.likedPosts = [PostFixtures.createPost()]
        sut.bookmarkedPosts = []

        // Then
        #expect(sut.engagementSummary.contains("いいね"))
    }
}
