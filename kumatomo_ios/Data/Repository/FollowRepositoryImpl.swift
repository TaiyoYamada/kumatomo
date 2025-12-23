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
        try await service.fetchFollowers(userId: userId, page: page, limit: limit)
    }

    func fetchFollowing(userId: Int, page: Int, limit: Int) async throws -> [FollowUser] {
        try await service.fetchFollowing(userId: userId, page: page, limit: limit)
    }
}
