import Foundation

// MARK: - EngagementAPIService

final class EngagementAPIService {
    static let shared = EngagementAPIService()

    private let client = APIClient.shared

    private init() {}

    // MARK: - Like Operations

    /// いいねをトグル
    func toggleLike(postId: Int) async throws -> LikeResponse {
        try await client.post(EngagementEndpoint.toggleLike(postId: postId))
    }

    /// いいね解除（後方互換性）
    func unlikePost(postId: Int) async throws -> LikeResponse {
        try await toggleLike(postId: postId)
    }

    // MARK: - Bookmark Operations

    /// ブックマークをトグル
    func toggleBookmark(postId: Int) async throws -> BookmarkResponse {
        try await client.post(EngagementEndpoint.toggleBookmark(postId: postId))
    }

    /// ブックマーク解除（後方互換性）
    func unbookmarkPost(postId: Int) async throws -> BookmarkResponse {
        try await toggleBookmark(postId: postId)
    }

    // MARK: - Fetch Operations

    /// いいねした投稿を取得
    func fetchLikedPosts(page: Int? = nil, limit: Int? = nil) async throws -> [Post] {
        let response: PaginatedResponse<Post> = try await client.get(
            EngagementEndpoint.fetchLikedPosts(page: page, limit: limit)
        )
        return response.data
    }

    /// ブックマークした投稿を取得
    func fetchBookmarkedPosts(page: Int? = nil, limit: Int? = nil) async throws -> [Post] {
        let response: PaginatedResponse<Post> = try await client.get(
            EngagementEndpoint.fetchBookmarkedPosts(page: page, limit: limit)
        )
        return response.data
    }

    // MARK: - Optimistic Updates

    /// オプティミスティックいいねトグル（UI即時更新用）
    func optimisticToggleLike(
        postId: Int,
        currentState _: Bool,
        currentCount _: Int
    ) async -> (success: Bool, response: (isLiked: Bool, likeCount: Int)?, error: EngagementError?) {
        do {
            let response = try await toggleLike(postId: postId)
            return (true, (response.isLiked, response.likeCount), nil)
        } catch let error as EngagementError {
            return (false, nil, error)
        } catch {
            return (false, nil, .networkError(error))
        }
    }

    /// オプティミスティックブックマークトグル（UI即時更新用）
    func optimisticToggleBookmark(
        postId: Int,
        currentState _: Bool,
        currentCount _: Int
    ) async -> (success: Bool, response: (isBookmarked: Bool, bookmarkCount: Int)?, error: EngagementError?) {
        do {
            let response = try await toggleBookmark(postId: postId)
            return (true, (response.isBookmarked, response.bookmarkCount), nil)
        } catch let error as EngagementError {
            return (false, nil, error)
        } catch {
            return (false, nil, .networkError(error))
        }
    }
}
