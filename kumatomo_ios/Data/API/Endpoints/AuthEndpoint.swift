import Foundation

// MARK: - AuthEndpoint

/// 認証API用エンドポイント定義
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
