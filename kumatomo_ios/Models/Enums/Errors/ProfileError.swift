import Foundation

enum ProfileError: LocalizedError {
    case invalidInput(field: String, message: String)
    case usernameNotAvailable
    case usernameCheckFailed(Error)
    case imageUploadFailed(Error)
    case networkError(Error)
    case validationFailed([String])
    case profileUpdateFailed(Error)
    case profileLoadFailed(Error)
    case unauthorized
    case serverError(statusCode: Int, message: String)
    
    // Enhanced error cases for comprehensive error handling
    case offlineError
    case imageCompressionFailed
    case imageSelectionFailed
    case imageTooLarge(maxSize: Int)
    case unsupportedImageFormat
    case uploadTimeout
    case uploadCancelled
    case rateLimitExceeded
    case quotaExceeded
    case serverMaintenance
    case connectionTimeout
    case slowConnection
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let field, let message):
            return "\(field): \(message)"
        case .usernameNotAvailable:
            return "このユーザーネームは既に使用されています"
        case .usernameCheckFailed(let error):
            return "ユーザーネームの確認に失敗しました: \(error.localizedDescription)"
        case .imageUploadFailed(let error):
            return "画像のアップロードに失敗しました: \(error.localizedDescription)"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .validationFailed(let messages):
            return messages.joined(separator: "\n")
        case .profileUpdateFailed(let error):
            return "プロフィールの更新に失敗しました: \(error.localizedDescription)"
        case .profileLoadFailed(let error):
            return "プロフィールの読み込みに失敗しました: \(error.localizedDescription)"
        case .unauthorized:
            return "認証エラー: ログインし直してください"
        case .serverError(let statusCode, let message):
            return "サーバーエラー (コード: \(statusCode)): \(message)"
        case .offlineError:
            return "インターネット接続がありません"
        case .imageCompressionFailed:
            return "画像の圧縮に失敗しました"
        case .imageSelectionFailed:
            return "画像の選択に失敗しました"
        case .imageTooLarge(let maxSize):
            return "画像サイズが大きすぎます（最大: \(maxSize)MB）"
        case .unsupportedImageFormat:
            return "サポートされていない画像形式です"
        case .uploadTimeout:
            return "アップロードがタイムアウトしました"
        case .uploadCancelled:
            return "アップロードがキャンセルされました"
        case .rateLimitExceeded:
            return "リクエスト制限に達しました。しばらく時間をおいてから再試行してください"
        case .quotaExceeded:
            return "ストレージ容量の上限に達しました"
        case .serverMaintenance:
            return "サーバーメンテナンス中です"
        case .connectionTimeout:
            return "接続がタイムアウトしました"
        case .slowConnection:
            return "接続が不安定です"
        case .dataCorrupted:
            return "データが破損しています"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidInput:
            return "入力内容を確認して修正してください"
        case .usernameNotAvailable:
            return "別のユーザーネームを試してください"
        case .usernameCheckFailed:
            return "しばらく時間をおいてから再試行してください"
        case .imageUploadFailed:
            return "画像のサイズを小さくするか、別の画像を選択してください"
        case .networkError:
            return "ネットワーク接続を確認してから再試行してください"
        case .validationFailed:
            return "入力内容を確認して修正してください"
        case .profileUpdateFailed:
            return "しばらく時間をおいてから再試行してください"
        case .profileLoadFailed:
            return "アプリを再起動するか、しばらく時間をおいてから再試行してください"
        case .unauthorized:
            return "ログインし直してください"
        case .serverError:
            return "しばらく時間をおいてから再試行してください"
        case .offlineError:
            return "Wi-Fiまたはモバイルデータ接続を確認してください"
        case .imageCompressionFailed:
            return "別の画像を選択してください"
        case .imageSelectionFailed:
            return "写真アプリから画像を選択し直してください"
        case .imageTooLarge:
            return "より小さいサイズの画像を選択してください"
        case .unsupportedImageFormat:
            return "JPEG、PNG、またはHEIC形式の画像を選択してください"
        case .uploadTimeout:
            return "ネットワーク接続を確認して再試行してください"
        case .uploadCancelled:
            return "再度アップロードを試してください"
        case .rateLimitExceeded:
            return "5分後に再試行してください"
        case .quotaExceeded:
            return "不要な画像を削除してから再試行してください"
        case .serverMaintenance:
            return "しばらく時間をおいてから再試行してください"
        case .connectionTimeout:
            return "ネットワーク接続を確認して再試行してください"
        case .slowConnection:
            return "より安定したネットワーク環境で再試行してください"
        case .dataCorrupted:
            return "アプリを再起動して再試行してください"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidInput:
            return "入力された情報が無効です"
        case .usernameNotAvailable:
            return "指定されたユーザーネームは既に他のユーザーが使用しています"
        case .usernameCheckFailed:
            return "ユーザーネームの重複確認処理でエラーが発生しました"
        case .imageUploadFailed:
            return "画像のアップロード処理でエラーが発生しました"
        case .networkError:
            return "ネットワーク接続に問題があります"
        case .validationFailed:
            return "入力された情報に不正な値が含まれています"
        case .profileUpdateFailed:
            return "プロフィール更新処理でエラーが発生しました"
        case .profileLoadFailed:
            return "プロフィール読み込み処理でエラーが発生しました"
        case .unauthorized:
            return "認証情報が無効です"
        case .serverError:
            return "サーバー側でエラーが発生しました"
        case .offlineError:
            return "デバイスがオフラインです"
        case .imageCompressionFailed:
            return "画像の圧縮処理に失敗しました"
        case .imageSelectionFailed:
            return "画像の選択処理に失敗しました"
        case .imageTooLarge:
            return "選択された画像のファイルサイズが制限を超えています"
        case .unsupportedImageFormat:
            return "選択された画像の形式がサポートされていません"
        case .uploadTimeout:
            return "アップロード処理がタイムアウトしました"
        case .uploadCancelled:
            return "アップロード処理がユーザーによってキャンセルされました"
        case .rateLimitExceeded:
            return "短時間に多数のリクエストが送信されました"
        case .quotaExceeded:
            return "ストレージの使用量が上限に達しています"
        case .serverMaintenance:
            return "サーバーがメンテナンス中です"
        case .connectionTimeout:
            return "サーバーとの接続がタイムアウトしました"
        case .slowConnection:
            return "ネットワーク接続が不安定です"
        case .dataCorrupted:
            return "送受信されたデータが破損しています"
        }
    }
    
    // MARK: - Error Classification
    
    /// Indicates if this error is recoverable through user action
    var isRecoverable: Bool {
        switch self {
        case .invalidInput, .usernameNotAvailable, .imageSelectionFailed, .imageTooLarge, .unsupportedImageFormat:
            return true
        case .offlineError, .networkError, .connectionTimeout, .slowConnection:
            return true
        case .usernameCheckFailed, .imageUploadFailed, .profileUpdateFailed, .uploadTimeout:
            return true
        case .unauthorized, .serverError, .serverMaintenance, .rateLimitExceeded, .quotaExceeded:
            return false
        case .validationFailed, .profileLoadFailed, .imageCompressionFailed, .uploadCancelled, .dataCorrupted:
            return true
        }
    }
    
    /// Indicates if this error should trigger an automatic retry
    var shouldAutoRetry: Bool {
        switch self {
        case .networkError, .connectionTimeout, .uploadTimeout, .slowConnection:
            return true
        case .serverError(let statusCode, _):
            return statusCode >= 500 // Only retry server errors, not client errors
        default:
            return false
        }
    }
    
    /// Returns the appropriate retry delay for this error
    var retryDelay: TimeInterval {
        switch self {
        case .networkError, .connectionTimeout:
            return 2.0
        case .uploadTimeout:
            return 5.0
        case .slowConnection:
            return 3.0
        case .serverError(let statusCode, _):
            return statusCode >= 500 ? 10.0 : 0.0
        case .rateLimitExceeded:
            return 300.0 // 5 minutes
        default:
            return 0.0
        }
    }
    
    /// Returns the maximum number of retry attempts for this error
    var maxRetryAttempts: Int {
        switch self {
        case .networkError, .connectionTimeout, .uploadTimeout:
            return 3
        case .slowConnection:
            return 2
        case .serverError(let statusCode, _):
            return statusCode >= 500 ? 2 : 0
        default:
            return 0
        }
    }
}

