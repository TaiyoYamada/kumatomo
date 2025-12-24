@testable import kumatomo
import Mockable
import Testing

// MARK: - FetchMunicipalityPostsUseCaseTests

/// 市町村投稿取得UseCaseのテスト
@Suite("FetchMunicipalityPostsUseCase Tests")
struct FetchMunicipalityPostsUseCaseTests {
    let mockRepository = MockPostRepository()

    @Test("市町村で投稿を取得できる")
    func executeShouldFetchMunicipalityPosts() async throws {
        // Given
        let expectedPosts = PostFixtures.samplePosts
        given(mockRepository)
            .fetchMunicipalityPosts(municipality: .any, page: .any, limit: .any)
            .willReturn(expectedPosts)

        // When
        let sut = FetchMunicipalityPostsUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(municipality: "八代市", page: 1, limit: 10)

        // Then
        #expect(result.count == expectedPosts.count)
        verify(mockRepository)
            .fetchMunicipalityPosts(municipality: .any, page: .any, limit: .any)
            .called(1)
    }
}
