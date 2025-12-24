@testable import kumatomo
import Mockable
import Testing

// MARK: - FetchUserPostsUseCaseTests

/// ユーザー投稿取得UseCaseのテスト
@Suite("FetchUserPostsUseCase Tests")
struct FetchUserPostsUseCaseTests {
    let mockRepository = MockPostRepository()

    @Test("ユーザーIDで投稿を取得できる")
    func executeShouldFetchUserPosts() async throws {
        // Given
        let userId = 1
        let expectedPosts = [PostFixtures.createPost(userId: userId)]
        given(mockRepository)
            .fetchUserPosts(userId: .value(userId), page: .any, limit: .any)
            .willReturn(expectedPosts)

        // When
        let sut = FetchUserPostsUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(userId: userId, page: 1, limit: 20)

        // Then
        #expect(result.count == expectedPosts.count)
        verify(mockRepository)
            .fetchUserPosts(userId: .value(userId), page: .any, limit: .any)
            .called(1)
    }
}
