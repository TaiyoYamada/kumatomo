@testable import kumatomo
import Mockable
import Testing

// MARK: - ToggleBookmarkUseCaseTests

/// ブックマーク切り替えUseCaseのテスト
@Suite("ToggleBookmarkUseCase Tests")
struct ToggleBookmarkUseCaseTests {
    let mockRepository = MockEngagementRepository()

    @Test("ブックマークしていない投稿を、ブックマークできる")
    func executeShouldBookmarkPost() async {
        // Given
        given(mockRepository)
            .optimisticToggleBookmark(postId: .any, currentState: .any, currentCount: .any)
            .willReturn((success: true, response: (isBookmarked: true, bookmarkCount: 4), error: nil))

        // When
        let sut = ToggleBookmarkUseCaseImpl(repository: mockRepository)
        let result = await sut.execute(postId: 1, currentState: false, currentCount: 3)

        // Then
        switch result {
        case let .success(value):
            #expect(value.isBookmarked == true)
            #expect(value.bookmarkCount == 4)
        case .failure:
            Issue.record("Expected success but got failure")
        }
    }

    @Test("ブックマーク済み投稿の、ブックマークを解除できる")
    func executeShouldUnbookmarkPost() async {
        // Given
        given(mockRepository)
            .optimisticToggleBookmark(postId: .any, currentState: .any, currentCount: .any)
            .willReturn((success: true, response: (isBookmarked: false, bookmarkCount: 9), error: nil))

        // When
        let sut = ToggleBookmarkUseCaseImpl(repository: mockRepository)
        let result = await sut.execute(postId: 1, currentState: true, currentCount: 10)

        // Then
        switch result {
        case let .success(value):
            #expect(value.isBookmarked == false)
            #expect(value.bookmarkCount == 9)
        case .failure:
            Issue.record("Expected success but got failure")
        }
    }
}
