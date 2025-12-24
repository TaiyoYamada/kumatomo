@testable import kumatomo
import Mockable
import Testing

// MARK: - FetchBookmarkedPostsUseCaseTests

/// ブックマークした投稿取得UseCaseのテスト
@Suite("FetchBookmarkedPostsUseCase Tests")
struct FetchBookmarkedPostsUseCaseTests {
    let mockRepository = MockEngagementRepository()

    @Test("ブックマークした投稿を取得できる")
    func executeShouldFetchBookmarkedPosts() async throws {
        // Given
        let expectedPosts = PostFixtures.samplePosts
        given(mockRepository)
            .fetchBookmarkedPosts(page: .any, limit: .any)
            .willReturn(expectedPosts)

        // When
        let sut = FetchBookmarkedPostsUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(page: 1, limit: 20)

        // Then
        #expect(result.count == expectedPosts.count)
        verify(mockRepository)
            .fetchBookmarkedPosts(page: .any, limit: .any)
            .called(1)
    }
}
