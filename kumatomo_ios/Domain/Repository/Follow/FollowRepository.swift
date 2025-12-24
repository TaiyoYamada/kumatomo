import Foundation

// MARK: - FollowRepositoryProtocol

/// フォロー機能のリポジトリプロトコル
protocol FollowRepositoryProtocol {
    /// ユーザーをフォロー
    func followUser(userId: Int) async throws

    /// フォロー解除
    func unfollowUser(userId: Int) async throws

    /// フォロワー一覧を取得
    func fetchFollowers(userId: Int, page: Int, limit: Int) async throws -> [FollowUser]

    /// フォロー中ユーザー一覧を取得
    func fetchFollowing(userId: Int, page: Int, limit: Int) async throws -> [FollowUser]
}
