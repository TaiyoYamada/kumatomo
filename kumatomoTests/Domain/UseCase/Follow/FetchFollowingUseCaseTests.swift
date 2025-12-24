@testable import kumatomo
import Mockable
import Testing

// MARK: - FetchFollowingUseCaseTests

/// フォロー中ユーザー取得UseCaseのテスト
@Suite("FetchFollowingUseCase Tests")
struct FetchFollowingUseCaseTests {
    let mockRepository = MockFollowRepositoryProtocol()

    @Test("ユーザーがフォロー中の一覧を取得できる")
    func executeShouldFetchFollowing() async throws {
        // Given
        let userId = 1
        let expectedFollowing = FollowFixtures.sampleFollowing
        given(mockRepository)
            .fetchFollowing(userId: .value(userId), page: .any, limit: .any)
            .willReturn(expectedFollowing)

        // When
        let sut = FetchFollowingUseCase(repository: mockRepository)
        let result = try await sut.execute(userId: userId, page: 1, limit: 20)

        // Then
        #expect(result.count == expectedFollowing.count)
        verify(mockRepository)
            .fetchFollowing(userId: .value(userId), page: .any, limit: .any)
            .called(1)
    }

    @Test("フォロー中がいない場合、空配列を返す")
    func executeShouldReturnEmptyArray() async throws {
        // Given
        given(mockRepository)
            .fetchFollowing(userId: .any, page: .any, limit: .any)
            .willReturn([])

        // When
        let sut = FetchFollowingUseCase(repository: mockRepository)
        let result = try await sut.execute(userId: 1, page: 1, limit: 20)

        // Then
        #expect(result.isEmpty)
    }
}
