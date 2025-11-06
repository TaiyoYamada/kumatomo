import Foundation

enum KumamonAIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(DecodingError)
    case apiError(statusCode: Int, message: String)
    case serverError(message: String)
    case unknownError(Error)
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case rateLimitExceeded
    case invalidResponse
    case aiServiceUnavailable
    case emptyMessage
    case invalidMessage
    case providerError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .decodingError(let error):
            return getDecodingErrorMessage(from: error)
        case .apiError(let statusCode, let message):
            return "APIエラー (コード: \(statusCode)): \(message)"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        case .unknownError(let error):
            return "未知のエラー: \(error.localizedDescription)"
        case .timeout:
            return "タイムアウトエラー"
        case .unauthorized:
            return "認証エラー"
        case .forbidden:
            return "アクセス権限がありません"
        case .notFound:
            return "リソースが見つかりません"
        case .rateLimitExceeded:
            return "リクエスト制限を超えています"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .aiServiceUnavailable:
            return "AIサービスが利用できません"
        case .emptyMessage:
            return "メッセージが空です"
        case .invalidMessage:
            return "無効なメッセージです"
        case .providerError(let message):
            return "AIプロバイダーエラー: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "URLを確認してください"
        case .networkError:
            return "ネットワーク接続を確認してください"
        case .decodingError:
            return "データ形式を確認してください"
        case .apiError:
            return "しばらく時間をおいてから再試行してください"
        case .serverError:
            return "サーバーの復旧をお待ちください"
        case .unknownError:
            return "アプリを再起動してください"
        case .timeout:
            return "通信環境を確認して再試行してください"
        case .unauthorized:
            return "ログインし直してください"
        case .forbidden:
            return "管理者に連絡してください"
        case .notFound:
            return "リソースが削除されている可能性があります"
        case .rateLimitExceeded:
            return "しばらく時間をおいてから再試行してください"
        case .invalidResponse:
            return "サーバーの応答内容を確認してください"
        case .aiServiceUnavailable:
            return "しばらく時間をおいてから再試行してください"
        case .emptyMessage:
            return "メッセージを入力してください"
        case .invalidMessage:
            return "有効なメッセージを入力してください"
        case .providerError:
            return "しばらく時間をおいてから再試行してください"
        }
    }

    var failureReason: String? {
        switch self {
        case .networkError:
            return "ネットワーク接続に問題があります"
        case .decodingError:
            return "サーバーからのデータ形式が正しくありません"
        case .apiError(let statusCode, _):
            return "サーバーがエラーを返しました (HTTP \(statusCode))"
        case .serverError:
            return "サーバー内部でエラーが発生しました"
        case .timeout:
            return "リクエストがタイムアウトしました"
        case .unauthorized:
            return "認証情報が無効です"
        case .forbidden:
            return "このリソースへのアクセス権限がありません"
        case .notFound:
            return "要求されたリソースが見つかりません"
        case .rateLimitExceeded:
            return "短時間に多くのリクエストが送信されました"
        case .invalidResponse:
            return "レスポンスの形式が想定と異なります"
        case .aiServiceUnavailable:
            return "AIサービスが一時的に利用できません"
        case .emptyMessage:
            return "メッセージが入力されていません"
        case .invalidMessage:
            return "メッセージの形式が正しくありません"
        case .providerError:
            return "AIプロバイダーでエラーが発生しました"
        default:
            return nil
        }
    }

    private func getDecodingErrorMessage(from error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, _):
            return "データ解析エラー: キーが見つかりません (\(key.stringValue))"
        case .valueNotFound(let type, _):
            return "データ解析エラー: 必須の値がありません (\(type))"
        case .typeMismatch(let type, _):
            return "データ解析エラー: データ型が一致しません (\(type))"
        case .dataCorrupted(let context):
            return "データ解析エラー: データが破損しています (\(context.debugDescription))"
        @unknown default:
            return "データ解析エラー: 未知のエラー"
        }
    }
}

enum AIServiceState: Equatable {
    case idle
    case loading
    case typing
    case error(KumamonAIError)
    case success

    static func == (lhs: AIServiceState, rhs: AIServiceState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.typing, .typing), (.success, .success):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}