import Foundation

/// エンゲージメントAPI用エンドポイント定義
enum EngagementEndpoint: APIEndpoint {
    case toggleLike(postId: Int)
    case toggleBookmark(postId: Int)
    case fetchLikedPosts(page: Int?, limit: Int?)
    case fetchBookmarkedPosts(page: Int?, limit: Int?)

    var path: String {
        switch self {
        case let .toggleLike(postId): return "/posts/\(postId)/like"
        case let .toggleBookmark(postId): return "/posts/\(postId)/bookmark"
        case .fetchLikedPosts: return "/user/liked-posts"
        case .fetchBookmarkedPosts: return "/user/bookmarked-posts"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .toggleLike, .toggleBookmark: return .post
        case .fetchLikedPosts, .fetchBookmarkedPosts: return .get
        }
    }

    var queryParameters: [String: Any]? {
        switch self {
        case let .fetchLikedPosts(page, limit),
             let .fetchBookmarkedPosts(page, limit):
            var params: [String: Any] = [:]
            if let page { params["page"] = page }
            if let limit { params["limit"] = limit }
            return params.isEmpty ? nil : params
        default:
            return nil
        }
    }
}
