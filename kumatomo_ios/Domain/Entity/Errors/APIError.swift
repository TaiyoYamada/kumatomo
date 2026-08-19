import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(DecodingError)
    case encodingError(Error)
    case apiError(statusCode: Int, message: String)
    case validationError(errors: [String: [String]])
    case serverError(message: String)
    case unknownError(Error)
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case rateLimitExceeded
    case invalidResponse
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case let .networkError(error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case let .decodingError(error):
            return getDecodingErrorMessage(from: error)
        case let .encodingError(error):
            return "データエンコードエラー: \(error.localizedDescription)"
        case let .apiError(statusCode, message):
            return "APIエラー (コード: \(statusCode)): \(message)"
        case let .validationError(errors):
            return parseValidationErrors(errors)
        case let .serverError(message):
            return "サーバーエラー: \(message)"
        case let .unknownError(error):
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
        case .userNotFound:
            return "ユーザーが見つかりません"
        }
    }

    /// Laravelバリデーションエラーをユーザーフレンドリーなメッセージに変換
    private func parseValidationErrors(_ errors: [String: [String]]) -> String {
        // メールアドレス重複エラー
        if let emailErrors = errors["email"] {
            for error in emailErrors {
                if error.contains("already been taken") || error.contains("unique") {
                    return "このメールアドレスは既に登録されています"
                }
                if error.contains("valid") || error.contains("format") {
                    return "メールアドレスの形式が正しくありません"
                }
            }
        }

        // パスワードエラー
        if let passwordErrors = errors["password"] {
            for error in passwordErrors {
                if error.contains("confirmation") || error.contains("一致") {
                    return "パスワードが一致しません"
                }
                if error.contains("min") || error.contains("6") {
                    return "パスワードは6文字以上で入力してください"
                }
            }
        }

        // その他のエラー: 最初のエラーメッセージを返す
        if let firstField = errors.keys.first,
           let firstErrors = errors[firstField],
           let firstError = firstErrors.first {
            return firstError
        }

        return "入力内容にエラーがあります"
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "URLを確認してください"
        case .networkError:
            return "ネットワーク接続を確認してください"
        case .decodingError:
            return "データ形式を確認してください"
        case .encodingError:
            return "送信データを確認してください"
        case .apiError:
            return "しばらく時間をおいてから再試行してください"
        case .validationError:
            return "入力内容を確認してください"
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
        case .userNotFound:
            return "ユーザーIDを確認してください"
        }
    }

    var failureReason: String? {
        switch self {
        case .networkError:
            return "ネットワーク接続に問題があります"
        case .decodingError:
            return "サーバーからのデータ形式が正しくありません"
        case .encodingError:
            return "送信データの形式に問題があります"
        case let .apiError(statusCode, _):
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
        case .userNotFound:
            return "指定されたユーザーが存在しません"
        default:
            return nil
        }
    }

    private func getDecodingErrorMessage(from error: DecodingError) -> String {
        switch error {
        case let .keyNotFound(key, _):
            return "データ解析エラー: キーが見つかりません (\(key.stringValue))"
        case let .valueNotFound(type, _):
            return "データ解析エラー: 必須の値がありません (\(type))"
        case let .typeMismatch(type, _):
            return "データ解析エラー: データ型が一致しません (\(type))"
        case let .dataCorrupted(context):
            return "データ解析エラー: データが破損しています (\(context.debugDescription))"
        @unknown default:
            return "データ解析エラー: 未知のエラー"
        }
    }
}
