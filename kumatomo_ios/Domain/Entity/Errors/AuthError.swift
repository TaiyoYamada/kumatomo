import Foundation

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case invalidResponse
    case registrationFailed
    case unauthorized
    case fetchUserFailed
    case logoutFailed
    case updateProfileFailed
    case userNotFound
    case serverError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "メールアドレスまたはパスワードが正しくありません"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .registrationFailed:
            return "ユーザー登録に失敗しました"
        case .unauthorized:
            return "認証が必要です"
        case .fetchUserFailed:
            return "ユーザー情報の取得に失敗しました"
        case .logoutFailed:
            return "ログアウトに失敗しました"
        case .updateProfileFailed:
            return "プロフィールの更新に失敗しました"
        case .userNotFound:
            return "ユーザー情報が見つかりません"
        case let .serverError(message):
            return message
        }
    }
}
