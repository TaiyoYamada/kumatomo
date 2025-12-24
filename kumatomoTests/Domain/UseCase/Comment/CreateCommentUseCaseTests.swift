import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - CreateCommentUseCaseTests

/// コメント作成UseCaseのテスト
@Suite("CreateCommentUseCase Tests")
struct CreateCommentUseCaseTests {
    let mockRepository = MockCommentRepository()

    @Test("テキストのみでコメントを作成できる")
    func executeShouldCreateTextComment() async throws {
        // Given
        let postId = 1
        let content = "新しいコメント"
        let expectedComment = Comment(id: 1, postId: postId, userId: 1, content: content)
        given(mockRepository)
            .createComment(postId: .value(postId), content: .value(content), imageData: .value(nil))
            .willReturn(expectedComment)

        // When
        let sut = CreateCommentUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(postId: postId, content: content, imageData: nil)

        // Then
        #expect(result.content == content)
        #expect(result.postId == postId)
        verify(mockRepository)
            .createComment(postId: .any, content: .any, imageData: .any)
            .called(1)
    }

    @Test("画像付きでコメントを作成できる")
    func executeShouldCreateCommentWithImage() async throws {
        // Given
        let postId = 1
        let content = "画像付きコメント"
        let imageData = Data([0x00, 0x01, 0x02])
        let expectedComment = Comment(
            id: 2,
            postId: postId,
            userId: 1,
            content: content,
            imageUrl: "https://example.com/image.jpg"
        )
        given(mockRepository)
            .createComment(postId: .any, content: .any, imageData: .any)
            .willReturn(expectedComment)

        // When
        let sut = CreateCommentUseCaseImpl(repository: mockRepository)
        let result = try await sut.execute(postId: postId, content: content, imageData: imageData)

        // Then
        #expect(result.content == content)
        #expect(result.imageUrl != nil)
    }

    @Test("リポジトリがエラーをスローした場合、エラーが伝播する")
    func executeShouldPropagateError() async {
        // Given
        given(mockRepository)
            .createComment(postId: .any, content: .any, imageData: .any)
            .willThrow(TestError.unauthorized)

        // When/Then
        let sut = CreateCommentUseCaseImpl(repository: mockRepository)
        await #expect(throws: TestError.self) {
            _ = try await sut.execute(postId: 1, content: "テスト", imageData: nil)
        }
    }
}
