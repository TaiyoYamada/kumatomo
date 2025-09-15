import Foundation

enum PostAPIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(Int, String)
    case unknownError(Error)
    case serverError(String)
    case timeout
    case engagementDataError(String)
    case authenticationRequired
    case postNotFound
    case insufficientPermissions
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .decodingError(let error):
            return "データの読み込みに失敗しました: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "APIエラー（コード: \(code)）: \(message)"
        case .unknownError(let error):
            return "不明なエラー: \(error.localizedDescription)"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        case .timeout:
            return "リクエストがタイムアウトしました"
        case .engagementDataError(let message):
            return "エンゲージメントデータエラー: \(message)"
        case .authenticationRequired:
            return "認証が必要です。ログインしてください"
        case .postNotFound:
            return "投稿が見つかりません"
        case .insufficientPermissions:
            return "この操作を実行する権限がありません"
        }
    }
    
    /// Returns true if the error is recoverable (e.g., network issues)
    var isRecoverable: Bool {
        switch self {
        case .networkError, .timeout, .serverError:
            return true
        case .engagementDataError:
            return true // エンゲージメントデータのエラーは通常リトライ可能
        default:
            return false
        }
    }
    
    /// Returns true if the error is related to engagement functionality
    var isEngagementRelated: Bool {
        switch self {
        case .engagementDataError:
            return true
        case .apiError(let code, _):
            // 特定のHTTPステータスコードをエンゲージメント関連として扱う
            return code >= 500 // サーバーエラーはエンゲージメントデータ取得失敗の可能性
        default:
            return false
        }
    }
}
