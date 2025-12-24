@testable import kumatomo
import Mockable
import Testing

// MARK: - FetchLikedPostsUseCaseTests

/// いいねした投稿取得UseCaseのテスト
@Suite("FetchLikedPostsUseCase Tests")
struct FetchLikedPostsUseCaseTests {
    let mockRepository = MockEngagementRepository()

    @Test("いいねした投稿を取得できる")
    func executeShouldFetchLikedPosts() async throws {
        // Given
        let expectedPosts = PostFixtures.samplePosts
        given(mockRepository)
            .fetchLikedPosts(page: .any, limit: .any)
            .willReturn(expectedPosts)

        // When
        let sut = FetchLikedPostsUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(page: 1, limit: 20)

        // Then
        #expect(result.count == expectedPosts.count)
        verify(mockRepository)
            .fetchLikedPosts(page: .any, limit: .any)
            .called(1)
    }
}
