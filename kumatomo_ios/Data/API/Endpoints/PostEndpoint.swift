import Foundation

// MARK: - PostEndpoint

/// 投稿API用エンドポイント定義
enum PostEndpoint: APIEndpoint {
    case fetchAll(page: Int?, limit: Int?)
    case fetchPost(id: Int)
    case fetchUserPosts(userId: Int, page: Int?, limit: Int?)
    case fetchMunicipalityPosts(municipality: String, page: Int?, limit: Int?)
    case fetchFollowingPosts(page: Int?, limit: Int?)
    case create(userId: Int, content: String, imageUrls: [String], tags: [String])
    case update(postId: Int, content: String, tags: [String])
    case delete(postId: Int)
    case toggleReaction(postId: Int, reactionType: String)
    case toggleBookmark(postId: Int)

    var path: String {
        switch self {
        case .fetchAll: return "/posts"
        case let .fetchPost(id): return "/posts/\(id)"
        case let .fetchUserPosts(userId, _, _): return "/users/\(userId)/posts"
        case let .fetchMunicipalityPosts(municipality, _, _):
            let encoded = municipality.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? municipality
            return "/posts/municipality/\(encoded)"
        case .fetchFollowingPosts: return "/posts/following"
        case .create: return "/posts"
        case let .update(postId, _, _): return "/posts/\(postId)"
        case let .delete(postId): return "/posts/\(postId)"
        case let .toggleReaction(postId, _): return "/posts/\(postId)/reactions"
        case let .toggleBookmark(postId): return "/posts/\(postId)/bookmark"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchAll, .fetchPost, .fetchUserPosts, .fetchMunicipalityPosts, .fetchFollowingPosts:
            return .get
        case .create, .toggleReaction, .toggleBookmark:
            return .post
        case .update:
            return .put
        case .delete:
            return .delete
        }
    }

    var queryParameters: [String: Any]? {
        switch self {
        case let .fetchAll(page, limit):
            var params: [String: Any] = [:]
            if let page { params["page"] = page }
            if let limit { params["limit"] = limit }
            return params.isEmpty ? nil : params
        case let .fetchUserPosts(_, page, limit),
             let .fetchMunicipalityPosts(_, page, limit),
             let .fetchFollowingPosts(page, limit):
            var params: [String: Any] = [:]
            if let page { params["page"] = page }
            if let limit { params["limit"] = limit }
            return params.isEmpty ? nil : params
        default:
            return nil
        }
    }

    var body: [String: Any]? {
        switch self {
        case let .create(userId, content, imageUrls, tags):
            var body: [String: Any] = ["user_id": userId, "content": content]
            if !imageUrls.isEmpty { body["image_urls"] = imageUrls }
            if !tags.isEmpty { body["tags"] = tags }
            return body
        case let .update(_, content, tags):
            var body: [String: Any] = ["content": content]
            if !tags.isEmpty { body["tags"] = tags }
            return body
        case let .toggleReaction(_, reactionType):
            return ["reaction_type": reactionType]
        default:
            return nil
        }
    }
}
