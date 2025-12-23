import Foundation
import Factory

// MARK: - FollowRepositoryImpl

/// フォロー機能リポジトリ実装
final class FollowRepositoryImpl: FollowRepositoryProtocol {
    private let service: UserAPIService

    init(service: UserAPIService = Container.shared.userAPIService()) {
        self.service = service
    }

    func followUser(userId: Int) async throws {
        try await service.followUser(userId: userId)
    }

    func unfollowUser(userId: Int) async throws {
        try await service.unfollowUser(userId: userId)
    }

    func fetchFollowers(userId: Int, page: Int, limit: Int) async throws -> [FollowUser] {
        // UserAPIService returns [User], convert to [FollowUser]
        let users = try await service.fetchFollowers(userId: userId, page: page, limit: limit)
        return users.map { user in
            FollowUser(
                id: user.id,
                name: user.name,
                username: user.username,
                profileImageURL: user.profileImageURL,
                bio: user.bio,
                isFollowing: nil,
                isMe: nil
            )
        }
    }

    func fetchFollowing(userId: Int, page: Int, limit: Int) async throws -> [FollowUser] {
        // UserAPIService returns [User], convert to [FollowUser]
        let users = try await service.fetchFollowing(userId: userId, page: page, limit: limit)
        return users.map { user in
            FollowUser(
                id: user.id,
                name: user.name,
                username: user.username,
                profileImageURL: user.profileImageURL,
                bio: user.bio,
                isFollowing: nil,
                isMe: nil
            )
        }
    }
}
