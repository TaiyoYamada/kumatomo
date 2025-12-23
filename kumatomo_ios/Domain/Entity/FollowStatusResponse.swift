import Foundation

// MARK: - FollowStatusResponse

/// フォロー状態のレスポンス
struct FollowStatusResponse: Codable, Sendable {
    let isFollowing: Bool
    let isFollowedBy: Bool
    let followersCount: Int
    let followingCount: Int

    enum CodingKeys: String, CodingKey {
        case isFollowing = "is_following"
        case isFollowedBy = "is_followed_by"
        case followersCount = "followers_count"
        case followingCount = "following_count"
    }
}
