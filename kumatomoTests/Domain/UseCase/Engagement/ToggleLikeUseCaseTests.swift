import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - ToggleLikeUseCaseTests

/// いいね切り替えUseCaseのテスト
@Suite("ToggleLikeUseCase Tests")
struct ToggleLikeUseCaseTests {
    let mockRepository = MockEngagementRepository()

    @Test("いいねしていない投稿に、いいねできる")
    func executeShouldLikePost() async {
        // Given
        given(mockRepository)
            .optimisticToggleLike(postId: .any, currentState: .any, currentCount: .any)
            .willReturn((success: true, response: (isLiked: true, likeCount: 6), error: nil))

        // When
        let sut = ToggleLikeUseCaseImpl(repository: mockRepository)
        let result = await sut.execute(postId: 1, currentState: false, currentCount: 5)

        // Then
        switch result {
        case let .success(value):
            #expect(value.isLiked == true)
            #expect(value.likeCount == 6)
        case .failure:
            Issue.record("Expected success but got failure")
        }
    }

    @Test("いいね済み投稿の、いいねを解除できる")
    func executeShouldUnlikePost() async {
        // Given
        given(mockRepository)
            .optimisticToggleLike(postId: .any, currentState: .any, currentCount: .any)
            .willReturn((success: true, response: (isLiked: false, likeCount: 9), error: nil))

        // When
        let sut = ToggleLikeUseCaseImpl(repository: mockRepository)
        let result = await sut.execute(postId: 1, currentState: true, currentCount: 10)

        // Then
        switch result {
        case let .success(value):
            #expect(value.isLiked == false)
            #expect(value.likeCount == 9)
        case .failure:
            Issue.record("Expected success but got failure")
        }
    }

    @Test("ネットワークエラー時、失敗を返す")
    func executeShouldReturnFailureOnNetworkError() async {
        // Given
        given(mockRepository)
            .optimisticToggleLike(postId: .any, currentState: .any, currentCount: .any)
            .willReturn((success: false, response: nil, error: .networkError(NSError(domain: "Network", code: -1))))

        // When
        let sut = ToggleLikeUseCaseImpl(repository: mockRepository)
        let result = await sut.execute(postId: 1, currentState: false, currentCount: 5)

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case let .failure(error):
            if case .networkError = error {
                // Expected
            } else {
                Issue.record("Expected network error")
            }
        }
    }

    @Test("認証エラー時、unauthorized エラーを返す")
    func executeShouldReturnUnauthorizedError() async {
        // Given
        given(mockRepository)
            .optimisticToggleLike(postId: .any, currentState: .any, currentCount: .any)
            .willReturn((success: false, response: nil, error: .unauthorized))

        // When
        let sut = ToggleLikeUseCaseImpl(repository: mockRepository)
        let result = await sut.execute(postId: 1, currentState: false, currentCount: 0)

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case let .failure(error):
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized error")
            }
        }
    }
}
