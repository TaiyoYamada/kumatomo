import Foundation

// MARK: - UserEndpoint

/// ユーザーAPI用エンドポイント定義
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
