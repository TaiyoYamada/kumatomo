import Foundation

// Domain layer protocol for engagement (likes/bookmarks, lists)
protocol EngagementRepository {
    func fetchLikedPosts(page: Int?, limit: Int?) async throws -> [Post]
    func fetchBookmarkedPosts(page: Int?, limit: Int?) async throws -> [Post]

    func optimisticToggleLike(postId: Int, currentState: Bool, currentCount: Int) async -> (success: Bool, response: (isLiked: Bool, likeCount: Int)?, error: EngagementError?)
    func optimisticToggleBookmark(postId: Int, currentState: Bool, currentCount: Int) async -> (success: Bool, response: (isBookmarked: Bool, bookmarkCount: Int)?, error: EngagementError?)

    func toggleLike(postId: Int) async throws -> (isLiked: Bool, likeCount: Int)
    func toggleBookmark(postId: Int) async throws -> (isBookmarked: Bool, bookmarkCount: Int)
}
