import Foundation

// Data adapter wrapping EngagementAPIService
final class EngagementRepositoryImpl: EngagementRepository {
    private let service: EngagementAPIService

    init(service: EngagementAPIService = .shared) {
        self.service = service
    }

    func fetchLikedPosts(page: Int?, limit: Int?) async throws -> [Post] {
        // Current API does not support page/limit in the service methods used in VM; call a simple fetch
        return try await service.fetchLikedPosts()
    }

    func fetchBookmarkedPosts(page: Int?, limit: Int?) async throws -> [Post] {
        return try await service.fetchBookmarkedPosts()
    }

    func optimisticToggleLike(postId: Int, currentState: Bool, currentCount: Int) async -> (success: Bool, response: (isLiked: Bool, likeCount: Int)?, error: EngagementError?) {
        let result = await service.optimisticToggleLike(postId: postId, currentState: currentState, currentCount: currentCount)
        if let resp = result.response {
            return (result.success, (isLiked: resp.isLiked, likeCount: resp.likeCount), result.error)
        } else {
            return (result.success, nil, result.error)
        }
    }

    func optimisticToggleBookmark(postId: Int, currentState: Bool, currentCount: Int) async -> (success: Bool, response: (isBookmarked: Bool, bookmarkCount: Int)?, error: EngagementError?) {
        let result = await service.optimisticToggleBookmark(postId: postId, currentState: currentState, currentCount: currentCount)
        if let resp = result.response {
            return (result.success, (isBookmarked: resp.isBookmarked, bookmarkCount: resp.bookmarkCount), result.error)
        } else {
            return (result.success, nil, result.error)
        }
    }

    func toggleLike(postId: Int) async throws -> (isLiked: Bool, likeCount: Int) {
        let response = try await service.toggleLike(postId: postId)
        return (isLiked: response.isLiked, likeCount: response.likeCount)
    }

    func toggleBookmark(postId: Int) async throws -> (isBookmarked: Bool, bookmarkCount: Int) {
        let response = try await service.toggleBookmark(postId: postId)
        return (isBookmarked: response.isBookmarked, bookmarkCount: response.bookmarkCount)
    }
}
