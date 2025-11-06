import Foundation

enum CommentError: LocalizedError {
    case emptyContent
    case contentTooLong(currentCount: Int, maxCount: Int)
    case imageUploadFailed(Error)
    case networkError(Error)
    case unauthorized
    case postNotFound
    case commentNotFound
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case apiError(Int, String)
    case serverError(String)
    case timeout
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "コメント内容を入力してください"
        case .contentTooLong(let current, let max):
            return "コメントが長すぎます (\(current)/\(max)文字)"
        case .imageUploadFailed(let error):
            return "画像のアップロードに失敗しました: \(error.localizedDescription)"
        case .networkError(let error):
            return "ネットワークエラーが発生しました: \(error.localizedDescription)"
        case .unauthorized:
            return "認証が必要です"
        case .postNotFound:
            return "投稿が見つかりません"
        case .commentNotFound:
            return "コメントが見つかりません"
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
        case .emptyContent:
            return "コメントを入力してから送信してください"
        case .contentTooLong:
            return "コメントを短くしてから送信してください"
        case .imageUploadFailed:
            return "画像を選び直すか、後でもう一度お試しください"
        case .networkError:
            return "インターネット接続を確認して、もう一度お試しください"
        case .unauthorized:
            return "ログインしてからもう一度お試しください"
        case .postNotFound:
            return "投稿が削除された可能性があります"
        case .commentNotFound:
            return "コメントが削除された可能性があります"
        case .timeout:
            return "しばらく待ってからもう一度お試しください"
        default:
            return "しばらく待ってからもう一度お試しください"
        }
    }
}