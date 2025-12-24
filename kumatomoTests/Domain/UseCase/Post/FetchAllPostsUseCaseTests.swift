@testable import kumatomo
import Mockable
import Testing

// MARK: - FetchAllPostsUseCaseTests

/// 全投稿取得UseCaseのテスト
@Suite("FetchAllPostsUseCase Tests")
struct FetchAllPostsUseCaseTests {
    let mockRepository = MockPostRepository()

    @Test("ページネーションパラメータで投稿を取得できる")
    func executeShouldReturnPosts() async throws {
        // Given
        let expectedPosts = PostFixtures.samplePosts
        given(mockRepository)
            .fetchAllPosts(page: .any, limit: .any)
            .willReturn(expectedPosts)

        // When
        let sut = FetchAllPostsUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(page: 1, limit: 10)

        // Then
        #expect(result.count == expectedPosts.count)
        verify(mockRepository)
            .fetchAllPosts(page: .any, limit: .any)
            .called(1)
    }

    @Test("リポジトリがエラーをスローした場合、エラーが伝播する")
    func executeShouldPropagateError() async throws {
        // Given
        given(mockRepository)
            .fetchAllPosts(page: .any, limit: .any)
            .willThrow(TestError.network)

        // When/Then
        let sut = FetchAllPostsUseCaseImpl(repository: mockRepository)
        await #expect(throws: TestError.self) {
            _ = try await sut.execute(page: 1, limit: 10)
        }
    }
}
