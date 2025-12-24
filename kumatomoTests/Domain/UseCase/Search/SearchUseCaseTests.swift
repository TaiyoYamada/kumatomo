import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - SearchUseCaseTests

/// 検索UseCaseのテスト
@Suite("SearchUseCase Tests")
struct SearchUseCaseTests {
    let mockRepository = MockSearchRepository()

    @Test("検索結果を取得できる")
    func executeShouldReturnSearchResults() async throws {
        // Given
        let query = "熊本"
        let pagination = SearchPagination(
            currentPage: 1,
            perPage: 20,
            posts: PaginationInfo(currentPage: 1, lastPage: 10, perPage: 20, total: 100)
        )
        let expectedResult = SearchResult(posts: PostFixtures.samplePosts, pagination: pagination)
        given(mockRepository)
            .search(query: .any, type: .any, page: .any, perPage: .any)
            .willReturn((expectedResult, 1, 10))

        // When
        let sut = SearchUseCaseImpl(repository: mockRepository)
        let (result, currentPage, totalPages) = try await sut.execute(
            query: query,
            type: .all,
            page: 1,
            perPage: 20
        )

        // Then
        #expect(result.posts.count == expectedResult.posts.count)
        #expect(currentPage == 1)
        #expect(totalPages == 10)
        verify(mockRepository)
            .search(query: .any, type: .any, page: .any, perPage: .any)
            .called(1)
    }

    @Test("検索結果が空の場合、空のSearchResultを返す")
    func executeShouldReturnEmptyResults() async throws {
        // Given
        let pagination = SearchPagination(currentPage: 1, perPage: 20, posts: nil)
        let emptyResult = SearchResult(posts: [], pagination: pagination)
        given(mockRepository)
            .search(query: .any, type: .any, page: .any, perPage: .any)
            .willReturn((emptyResult, 1, 0))

        // When
        let sut = SearchUseCaseImpl(repository: mockRepository)
        let (result, _, totalPages) = try await sut.execute(
            query: "存在しない",
            type: .all,
            page: 1,
            perPage: 20
        )

        // Then
        #expect(result.posts.isEmpty)
        #expect(totalPages == 0)
    }

    @Test("リポジトリがエラーをスローした場合、エラーが伝播する")
    func executeShouldPropagateError() async {
        // Given
        given(mockRepository)
            .search(query: .any, type: .any, page: .any, perPage: .any)
            .willThrow(TestError.network)

        // When/Then
        let sut = SearchUseCaseImpl(repository: mockRepository)
        await #expect(throws: TestError.self) {
            _ = try await sut.execute(query: "test", type: .all, page: 1, perPage: 20)
        }
    }
}
