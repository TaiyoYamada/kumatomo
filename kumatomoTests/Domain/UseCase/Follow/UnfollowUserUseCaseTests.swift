@testable import kumatomo
import Mockable
import Testing

// MARK: - UnfollowUserUseCaseTests

/// フォロー解除UseCaseのテスト
@Suite("UnfollowUserUseCase Tests")
struct UnfollowUserUseCaseTests {
    let mockRepository = MockFollowRepositoryProtocol()

    @Test("ユーザーのフォローを解除できる")
    func executeShouldUnfollowUser() async throws {
        // Given
        let userId = 1
        given(mockRepository)
            .unfollowUser(userId: .value(userId))
            .willReturn(())

        // When
        let sut = UnfollowUserUseCase(repository: mockRepository)
        try await sut.execute(userId: userId)

        // Then
        verify(mockRepository)
            .unfollowUser(userId: .value(userId))
            .called(1)
    }

    @Test("リポジトリがエラーをスローした場合、エラーが伝播する")
    func executeShouldPropagateError() async {
        // Given
        given(mockRepository)
            .unfollowUser(userId: .any)
            .willThrow(TestError.network)

        // When/Then
        let sut = UnfollowUserUseCase(repository: mockRepository)
        await #expect(throws: TestError.self) {
            try await sut.execute(userId: 1)
        }
    }
}
