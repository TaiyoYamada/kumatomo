import Foundation

/// パスワードリセットAPI用エンドポイント定義
enum PasswordResetEndpoint: APIEndpoint {
    case forgotPassword(email: String)
    case verifyCode(email: String, code: String)
    case resetPassword(token: String, password: String, passwordConfirmation: String)

    var path: String {
        switch self {
        case .forgotPassword: return "/forgot-password"
        case .verifyCode: return "/verify-reset-code"
        case .resetPassword: return "/reset-password"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .forgotPassword, .verifyCode, .resetPassword:
            return .post
        }
    }

    var body: [String: Any]? {
        switch self {
        case let .forgotPassword(email):
            return ["email": email]
        case let .verifyCode(email, code):
            return ["email": email, "code": code]
        case let .resetPassword(token, password, passwordConfirmation):
            return [
                "token": token,
                "password": password,
                "password_confirmation": passwordConfirmation
            ]
        }
    }

    var requiresAuth: Bool {
        // パスワードリセットは認証不要
        false
    }
}
