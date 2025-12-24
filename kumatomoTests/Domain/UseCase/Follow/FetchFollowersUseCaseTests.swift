@testable import kumatomo
import Mockable
import Testing

// MARK: - FetchFollowersUseCaseTests

/// フォロワー取得UseCaseのテスト
@Suite("FetchFollowersUseCase Tests")
struct FetchFollowersUseCaseTests {
    let mockRepository = MockFollowRepositoryProtocol()

    @Test("ユーザーのフォロワー一覧を取得できる")
    func executeShouldFetchFollowers() async throws {
        // Given
        let userId = 1
        let expectedFollowers = FollowFixtures.sampleFollowers
        given(mockRepository)
            .fetchFollowers(userId: .value(userId), page: .any, limit: .any)
            .willReturn(expectedFollowers)

        // When
        let sut = FetchFollowersUseCase(repository: mockRepository)
        let result = try await sut.execute(userId: userId, page: 1, limit: 20)

        // Then
        #expect(result.count == expectedFollowers.count)
        verify(mockRepository)
            .fetchFollowers(userId: .value(userId), page: .any, limit: .any)
            .called(1)
    }

    @Test("フォロワーがいない場合、空配列を返す")
    func executeShouldReturnEmptyArray() async throws {
        // Given
        given(mockRepository)
            .fetchFollowers(userId: .any, page: .any, limit: .any)
            .willReturn([])

        // When
        let sut = FetchFollowersUseCase(repository: mockRepository)
        let result = try await sut.execute(userId: 1, page: 1, limit: 20)

        // Then
        #expect(result.isEmpty)
    }
}

// MARK: - FollowFixtures

enum FollowFixtures {
    static let sampleFollowers: [FollowUser] = [
        FollowUser(id: 1, name: "ユーザー1", username: "user1", profileImageURL: nil, bio: nil, isFollowing: false, isMe: false),
        FollowUser(id: 2, name: "ユーザー2", username: "user2", profileImageURL: nil, bio: nil, isFollowing: true, isMe: false),
    ]

    static let sampleFollowing: [FollowUser] = [
        FollowUser(id: 3, name: "ユーザー3", username: "user3", profileImageURL: nil, bio: "テスト", isFollowing: true, isMe: false),
    ]
}
