import Foundation

// MARK: - HTTPMethod

/// HTTPメソッド
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - APIEndpoint

/// 型安全なAPIエンドポイント定義
protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: Any]? { get }
    var body: [String: Any]? { get }
    var requiresAuth: Bool { get }
}

// MARK: - Default Implementations

extension APIEndpoint {
    var headers: [String: String]? { nil }
    var queryParameters: [String: Any]? { nil }
    var body: [String: Any]? { nil }
    var requiresAuth: Bool { true }
}

// MARK: - AuthEndpoint

enum AuthEndpoint: APIEndpoint {
    case login(email: String, password: String)
    case register(email: String, password: String)
    case logout
    case currentUser
    case updateUser(data: [String: Any])

    var path: String {
        switch self {
        case .login: return "/login"
        case .register: return "/register"
        case .logout: return "/logout"
        case .currentUser: return "/user"
        case .updateUser: return "/user/update"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register: return .post
        case .logout: return .post
        case .currentUser: return .get
        case .updateUser: return .put
        }
    }

    var body: [String: Any]? {
        switch self {
        case let .login(email, password):
            return ["email": email, "password": password]
        case let .register(email, password):
            return ["email": email, "password": password]
        case let .updateUser(data):
            return data
        default:
            return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .login, .register: return false
        default: return true
        }
    }
}

// MARK: - PostEndpoint

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

// MARK: - EngagementEndpoint

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

// MARK: - UserEndpoint

enum UserEndpoint: APIEndpoint {
    case fetchUser(userId: Int)
    case updateProfile(data: [String: Any])
    case follow(userId: Int)
    case unfollow(userId: Int)
    case fetchFollowers(userId: Int, page: Int?, limit: Int?)
    case fetchFollowing(userId: Int, page: Int?, limit: Int?)

    var path: String {
        switch self {
        case let .fetchUser(userId): return "/users/\(userId)"
        case .updateProfile: return "/user/update"
        case let .follow(userId): return "/users/\(userId)/follow"
        case let .unfollow(userId): return "/users/\(userId)/unfollow"
        case let .fetchFollowers(userId, _, _): return "/users/\(userId)/followers"
        case let .fetchFollowing(userId, _, _): return "/users/\(userId)/following"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchUser, .fetchFollowers, .fetchFollowing: return .get
        case .updateProfile: return .put
        case .follow, .unfollow: return .post
        }
    }

    var queryParameters: [String: Any]? {
        switch self {
        case let .fetchFollowers(_, page, limit),
             let .fetchFollowing(_, page, limit):
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
        case let .updateProfile(data): return data
        default: return nil
        }
    }
}
