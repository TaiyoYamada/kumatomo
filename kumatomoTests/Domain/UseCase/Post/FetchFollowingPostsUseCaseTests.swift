@testable import kumatomo
import Mockable
import Testing

// MARK: - FetchFollowingPostsUseCaseTests

/// フォロー中ユーザー投稿取得UseCaseのテスト
@Suite("FetchFollowingPostsUseCase Tests")
struct FetchFollowingPostsUseCaseTests {
    let mockRepository = MockPostRepository()

    @Test("フォロー中ユーザーの投稿を取得できる")
    func executeShouldFetchFollowingPosts() async throws {
        // Given
        let expectedPosts = PostFixtures.samplePosts
        given(mockRepository)
            .fetchFollowingPosts(page: .any, limit: .any)
            .willReturn(expectedPosts)

        // When
        let sut = FetchFollowingPostsUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(page: 1, limit: 10)

        // Then
        #expect(result.count == expectedPosts.count)
        verify(mockRepository)
            .fetchFollowingPosts(page: .any, limit: .any)
            .called(1)
    }

    @Test("フォローがない場合、空配列を返す")
    func executeShouldReturnEmptyWhenNoFollowing() async throws {
        // Given
        given(mockRepository)
            .fetchFollowingPosts(page: .any, limit: .any)
            .willReturn([])

        // When
        let sut = FetchFollowingPostsUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(page: 1, limit: 10)

        // Then
        #expect(result.isEmpty)
    }
}
