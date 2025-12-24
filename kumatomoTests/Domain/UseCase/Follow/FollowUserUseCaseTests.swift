@testable import kumatomo
import Mockable
import Testing

// MARK: - FollowUserUseCaseTests

/// フォローUseCaseのテスト
@Suite("FollowUserUseCase Tests")
struct FollowUserUseCaseTests {
    let mockRepository = MockFollowRepositoryProtocol()

    @Test("ユーザーをフォローできる")
    func executeShouldFollowUser() async throws {
        // Given
        let userId = 1
        given(mockRepository)
            .followUser(userId: .value(userId))
            .willReturn(())

        // When
        let sut = FollowUserUseCase(repository: mockRepository)
        try await sut.execute(userId: userId)

        // Then
        verify(mockRepository)
            .followUser(userId: .value(userId))
            .called(1)
    }

    @Test("リポジトリがエラーをスローした場合、エラーが伝播する")
    func executeShouldPropagateError() async {
        // Given
        given(mockRepository)
            .followUser(userId: .any)
            .willThrow(TestError.network)

        // When/Then
        let sut = FollowUserUseCase(repository: mockRepository)
        await #expect(throws: TestError.self) {
            try await sut.execute(userId: 1)
        }
    }
}
