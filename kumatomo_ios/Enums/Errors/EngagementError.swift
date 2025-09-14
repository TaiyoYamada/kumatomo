import Foundation

enum EngagementError: LocalizedError {
    case networkError(Error)
    case unauthorized
    case postNotFound
    case alreadyLiked
    case alreadyBookmarked
    case notLiked
    case notBookmarked
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case apiError(Int, String)
    case serverError(String)
    case timeout
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "ネットワークエラーが発生しました: \(error.localizedDescription)"
        case .unauthorized:
            return "認証が必要です"
        case .postNotFound:
            return "投稿が見つかりません"
        case .alreadyLiked:
            return "既にいいねしています"
        case .alreadyBookmarked:
            return "既にブックマークしています"
        case .notLiked:
            return "いいねしていません"
        case .notBookmarked:
            return "ブックマークしていません"
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .decodingError(let error):
            return "データの読み込みに失敗しました: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "APIエラー（コード: \(code)）: \(message)"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        case .timeout:
            return "リクエストがタイムアウトしました"
        case .unknownError(let error):
            return "不明なエラー: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "インターネット接続を確認して、もう一度お試しください"
        case .unauthorized:
            return "ログインしてからもう一度お試しください"
        case .postNotFound:
            return "投稿が削除された可能性があります"
        case .alreadyLiked, .alreadyBookmarked:
            return "既に操作済みです"
        case .notLiked, .notBookmarked:
            return "まず操作を行ってください"
        case .timeout:
            return "しばらく待ってからもう一度お試しください"
        default:
            return "しばらく待ってからもう一度お試しください"
        }
    }
}