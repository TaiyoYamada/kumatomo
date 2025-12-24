import Factory
@testable import kumatomo
import Mockable
import Testing

// MARK: - FollowViewModelTests

/// フォローViewModelのテスト
@Suite("FollowViewModel Tests")
@MainActor
struct FollowViewModelTests {
    @Test("初期状態では空のフォロワー/フォロイング一覧")
    func initialStateShouldBeEmpty() async {
        // Given
        let sut = FollowViewModel()

        // Then
        #expect(sut.followers.isEmpty)
        #expect(sut.following.isEmpty)
        #expect(sut.isLoadingFollowers == false)
        #expect(sut.isLoadingFollowing == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("hasMoreFollowersは初期状態でtrue")
    func hasMoreFollowersShouldBeTrueInitially() async {
        // Given
        let sut = FollowViewModel()

        // Then
        #expect(sut.hasMoreFollowers == true)
        #expect(sut.hasMoreFollowing == true)
    }

    @Test("isFollowActionInProgressは初期状態でfalse")
    func isFollowActionInProgressShouldBeFalseInitially() async {
        // Given
        let sut = FollowViewModel()

        // Then
        #expect(sut.isFollowActionInProgress == false)
    }

    @Test("updateFollowStatusでフォロー状態を更新できる")
    func updateFollowStatusShouldUpdateState() async {
        // Given
        let sut = FollowViewModel()

        // When - update status (no users in list, should not crash)
        sut.updateFollowStatus(userId: 1, isFollowing: true)

        // Then - should not crash and complete
        #expect(sut.followers.isEmpty)
    }
}
