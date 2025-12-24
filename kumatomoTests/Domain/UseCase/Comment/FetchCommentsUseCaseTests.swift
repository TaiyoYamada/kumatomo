import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - FetchCommentsUseCaseTests

/// コメント取得UseCaseのテスト
@Suite("FetchCommentsUseCase Tests")
struct FetchCommentsUseCaseTests {
    let mockRepository = MockCommentRepository()

    @Test("コメントを取得できる")
    func executeShouldReturnComments() async throws {
        // Given
        let postId = 1
        let expectedComments = [
            Comment(id: 1, postId: postId, userId: 1, content: "コメント1"),
            Comment(id: 2, postId: postId, userId: 2, content: "コメント2"),
        ]
        given(mockRepository)
            .fetchComments(postId: .value(postId))
            .willReturn(expectedComments)

        // When
        let sut = FetchCommentsUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(postId: postId)

        // Then
        #expect(result.count == 2)
        verify(mockRepository)
            .fetchComments(postId: .any)
            .called(1)
    }

    @Test("コメントが空の場合、空配列を返す")
    func executeShouldReturnEmptyArray() async throws {
        // Given
        given(mockRepository)
            .fetchComments(postId: .any)
            .willReturn([])

        // When
        let sut = FetchCommentsUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(postId: 1)

        // Then
        #expect(result.isEmpty)
    }

    @Test("リポジトリがエラーをスローした場合、エラーが伝播する")
    func executeShouldPropagateError() async {
        // Given
        given(mockRepository)
            .fetchComments(postId: .any)
            .willThrow(TestError.network)

        // When/Then
        let sut = FetchCommentsUseCaseImpl(repository: mockRepository)
        await #expect(throws: TestError.self) {
            _ = try await sut.execute(postId: 1)
        }
    }
}
