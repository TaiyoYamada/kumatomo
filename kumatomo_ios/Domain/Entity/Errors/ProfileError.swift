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

    case profileCreationFailed(Error)
    case profileDeletionFailed(Error)
    case profileNotFound
    case duplicateProfile
    case insufficientPermissions
    case accountSuspended
    case accountDeleted
    case deviceStorageFull
    case backgroundTaskExpired
    case concurrentModification
    case dataIntegrityError
    case serviceUnavailable
    case maintenanceMode
    case featureDisabled
    case geoLocationRestricted
    case ageRestricted
    case contentModerated
    case spamDetected
    case maliciousContentDetected
    case privacyViolation
    case termsViolation
    case copyrightViolation
    case inappropriateContent
    case technicalDifficulties
    case temporaryServiceIssue
    case permanentServiceIssue
    case configurationError
    case dependencyFailure
    case thirdPartyServiceError(service: String, error: Error)
    case cacheCorrupted
    case syncConflict
    case versionMismatch
    case platformNotSupported
    case featureNotAvailable
    case resourceExhausted
    case operationCancelled
    case operationTimeout
    case invalidState
    case preconditionFailed
    case postconditionFailed
    case businessRuleViolation(rule: String)
    case securityViolation
    case fraudDetected
    case suspiciousActivity

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
        case .profileCreationFailed(let error):
            return "プロフィールの作成に失敗しました: \(error.localizedDescription)"
        case .profileDeletionFailed(let error):
            return "プロフィールの削除に失敗しました: \(error.localizedDescription)"
        case .profileNotFound:
            return "プロフィールが見つかりません"
        case .duplicateProfile:
            return "このプロフィールは既に存在します"
        case .insufficientPermissions:
            return "この操作を実行する権限がありません"
        case .accountSuspended:
            return "アカウントが一時停止されています"
        case .accountDeleted:
            return "アカウントが削除されています"
        case .deviceStorageFull:
            return "デバイスの容量が不足しています"
        case .backgroundTaskExpired:
            return "バックグラウンド処理がタイムアウトしました"
        case .concurrentModification:
            return "他のデバイスで同時に変更が行われました"
        case .dataIntegrityError:
            return "データの整合性に問題があります"
        case .serviceUnavailable:
            return "サービスが一時的に利用できません"
        case .maintenanceMode:
            return "メンテナンス中のため利用できません"
        case .featureDisabled:
            return "この機能は現在無効になっています"
        case .geoLocationRestricted:
            return "お住まいの地域ではこの機能をご利用いただけません"
        case .ageRestricted:
            return "年齢制限により利用できません"
        case .contentModerated:
            return "コンテンツが審査中です"
        case .spamDetected:
            return "スパムとして検出されました"
        case .maliciousContentDetected:
            return "悪意のあるコンテンツが検出されました"
        case .privacyViolation:
            return "プライバシーポリシーに違反しています"
        case .termsViolation:
            return "利用規約に違反しています"
        case .copyrightViolation:
            return "著作権に違反しています"
        case .inappropriateContent:
            return "不適切なコンテンツが含まれています"
        case .technicalDifficulties:
            return "技術的な問題が発生しています"
        case .temporaryServiceIssue:
            return "一時的なサービス障害が発生しています"
        case .permanentServiceIssue:
            return "サービスに問題が発生しています"
        case .configurationError:
            return "設定に問題があります"
        case .dependencyFailure:
            return "依存サービスに問題があります"
        case .thirdPartyServiceError(let service, let error):
            return "\(service)サービスでエラーが発生しました: \(error.localizedDescription)"
        case .cacheCorrupted:
            return "キャッシュデータが破損しています"
        case .syncConflict:
            return "データの同期で競合が発生しました"
        case .versionMismatch:
            return "アプリのバージョンが対応していません"
        case .platformNotSupported:
            return "このプラットフォームはサポートされていません"
        case .featureNotAvailable:
            return "この機能は利用できません"
        case .resourceExhausted:
            return "リソースが不足しています"
        case .operationCancelled:
            return "操作がキャンセルされました"
        case .operationTimeout:
            return "操作がタイムアウトしました"
        case .invalidState:
            return "無効な状態です"
        case .preconditionFailed:
            return "前提条件が満たされていません"
        case .postconditionFailed:
            return "処理後の条件が満たされていません"
        case .businessRuleViolation(let rule):
            return "ビジネスルール違反: \(rule)"
        case .securityViolation:
            return "セキュリティ違反が検出されました"
        case .fraudDetected:
            return "不正行為が検出されました"
        case .suspiciousActivity:
            return "疑わしい活動が検出されました"
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
        case .profileCreationFailed:
            return "入力内容を確認して再試行してください"
        case .profileDeletionFailed:
            return "しばらく時間をおいてから再試行してください"
        case .profileNotFound:
            return "プロフィールを再作成してください"
        case .duplicateProfile:
            return "既存のプロフィールを使用するか、異なる情報で作成してください"
        case .insufficientPermissions:
            return "管理者に権限の付与を依頼してください"
        case .accountSuspended:
            return "サポートにお問い合わせください"
        case .accountDeleted:
            return "新しいアカウントを作成してください"
        case .deviceStorageFull:
            return "デバイスの容量を確保してから再試行してください"
        case .backgroundTaskExpired:
            return "アプリをフォアグラウンドで再試行してください"
        case .concurrentModification:
            return "最新のデータを取得してから再試行してください"
        case .dataIntegrityError:
            return "データを再同期してください"
        case .serviceUnavailable:
            return "しばらく時間をおいてから再試行してください"
        case .maintenanceMode:
            return "メンテナンス終了後に再試行してください"
        case .featureDisabled:
            return "アプリを最新版に更新してください"
        case .geoLocationRestricted:
            return "サポートされている地域からアクセスしてください"
        case .ageRestricted:
            return "年齢確認を完了してください"
        case .contentModerated:
            return "審査完了まで少々お待ちください"
        case .spamDetected:
            return "コンテンツを見直して再投稿してください"
        case .maliciousContentDetected:
            return "安全なコンテンツに変更してください"
        case .privacyViolation:
            return "プライバシーポリシーを確認して修正してください"
        case .termsViolation:
            return "利用規約を確認して修正してください"
        case .copyrightViolation:
            return "著作権に配慮したコンテンツに変更してください"
        case .inappropriateContent:
            return "適切なコンテンツに変更してください"
        case .technicalDifficulties:
            return "しばらく時間をおいてから再試行してください"
        case .temporaryServiceIssue:
            return "サービス復旧まで少々お待ちください"
        case .permanentServiceIssue:
            return "サポートにお問い合わせください"
        case .configurationError:
            return "アプリを再インストールしてください"
        case .dependencyFailure:
            return "しばらく時間をおいてから再試行してください"
        case .thirdPartyServiceError:
            return "外部サービスの復旧をお待ちください"
        case .cacheCorrupted:
            return "アプリのデータをクリアして再起動してください"
        case .syncConflict:
            return "データを手動で同期してください"
        case .versionMismatch:
            return "アプリを最新版に更新してください"
        case .platformNotSupported:
            return "サポートされているデバイスをご利用ください"
        case .featureNotAvailable:
            return "アプリを最新版に更新してください"
        case .resourceExhausted:
            return "しばらく時間をおいてから再試行してください"
        case .operationCancelled:
            return "操作を再実行してください"
        case .operationTimeout:
            return "ネットワーク環境を確認して再試行してください"
        case .invalidState:
            return "アプリを再起動してください"
        case .preconditionFailed:
            return "必要な条件を満たしてから再試行してください"
        case .postconditionFailed:
            return "処理を最初からやり直してください"
        case .businessRuleViolation:
            return "ルールに従って修正してください"
        case .securityViolation:
            return "セキュリティ設定を確認してください"
        case .fraudDetected:
            return "本人確認を完了してください"
        case .suspiciousActivity:
            return "アカウントのセキュリティを確認してください"
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
        case .profileCreationFailed:
            return "プロフィール作成処理でエラーが発生しました"
        case .profileDeletionFailed:
            return "プロフィール削除処理でエラーが発生しました"
        case .profileNotFound:
            return "指定されたプロフィールが存在しません"
        case .duplicateProfile:
            return "同じプロフィール情報が既に登録されています"
        case .insufficientPermissions:
            return "操作に必要な権限が不足しています"
        case .accountSuspended:
            return "アカウントが管理者によって停止されています"
        case .accountDeleted:
            return "アカウントが削除されています"
        case .deviceStorageFull:
            return "デバイスの利用可能容量が不足しています"
        case .backgroundTaskExpired:
            return "バックグラウンド処理の制限時間を超過しました"
        case .concurrentModification:
            return "複数のデバイスから同時に変更が行われました"
        case .dataIntegrityError:
            return "データの整合性チェックに失敗しました"
        case .serviceUnavailable:
            return "サービスが一時的に利用できない状態です"
        case .maintenanceMode:
            return "システムメンテナンス中です"
        case .featureDisabled:
            return "この機能は管理者によって無効化されています"
        case .geoLocationRestricted:
            return "地理的制限により利用できません"
        case .ageRestricted:
            return "年齢制限により利用が制限されています"
        case .contentModerated:
            return "コンテンツが審査待ちの状態です"
        case .spamDetected:
            return "スパムフィルターによって検出されました"
        case .maliciousContentDetected:
            return "セキュリティスキャンで悪意のあるコンテンツが検出されました"
        case .privacyViolation:
            return "プライバシーポリシーに違反するコンテンツが含まれています"
        case .termsViolation:
            return "利用規約に違反するコンテンツが含まれています"
        case .copyrightViolation:
            return "著作権を侵害するコンテンツが含まれています"
        case .inappropriateContent:
            return "コミュニティガイドラインに違反するコンテンツが含まれています"
        case .technicalDifficulties:
            return "システムで技術的な問題が発生しています"
        case .temporaryServiceIssue:
            return "一時的なサービス障害が発生しています"
        case .permanentServiceIssue:
            return "サービスに恒久的な問題が発生しています"
        case .configurationError:
            return "アプリケーションの設定に問題があります"
        case .dependencyFailure:
            return "依存する外部サービスに問題があります"
        case .thirdPartyServiceError:
            return "連携している外部サービスでエラーが発生しました"
        case .cacheCorrupted:
            return "ローカルキャッシュデータが破損しています"
        case .syncConflict:
            return "データ同期時に競合が発生しました"
        case .versionMismatch:
            return "アプリのバージョンがサーバーと互換性がありません"
        case .platformNotSupported:
            return "現在のプラットフォームはサポートされていません"
        case .featureNotAvailable:
            return "この機能は現在のバージョンでは利用できません"
        case .resourceExhausted:
            return "システムリソースが不足しています"
        case .operationCancelled:
            return "操作がユーザーまたはシステムによってキャンセルされました"
        case .operationTimeout:
            return "操作の制限時間を超過しました"
        case .invalidState:
            return "アプリケーションが無効な状態にあります"
        case .preconditionFailed:
            return "操作の前提条件が満たされていません"
        case .postconditionFailed:
            return "操作後の期待される状態になっていません"
        case .businessRuleViolation:
            return "ビジネスルールに違反しています"
        case .securityViolation:
            return "セキュリティポリシーに違反する行為が検出されました"
        case .fraudDetected:
            return "不正行為の可能性が検出されました"
        case .suspiciousActivity:
            return "疑わしい活動パターンが検出されました"
        }
    }


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
        case .profileCreationFailed, .profileDeletionFailed, .profileNotFound:
            return true
        case .duplicateProfile, .deviceStorageFull, .backgroundTaskExpired:
            return true
        case .concurrentModification, .dataIntegrityError, .cacheCorrupted, .syncConflict:
            return true
        case .serviceUnavailable, .technicalDifficulties, .temporaryServiceIssue:
            return true
        case .configurationError, .dependencyFailure, .thirdPartyServiceError:
            return true
        case .versionMismatch, .featureNotAvailable, .resourceExhausted:
            return true
        case .operationCancelled, .operationTimeout, .invalidState:
            return true
        case .preconditionFailed, .postconditionFailed:
            return true
        case .insufficientPermissions, .accountSuspended, .accountDeleted:
            return false
        case .maintenanceMode, .featureDisabled, .geoLocationRestricted, .ageRestricted:
            return false
        case .contentModerated, .spamDetected, .maliciousContentDetected:
            return false
        case .privacyViolation, .termsViolation, .copyrightViolation, .inappropriateContent:
            return false
        case .permanentServiceIssue, .platformNotSupported:
            return false
        case .businessRuleViolation, .securityViolation, .fraudDetected, .suspiciousActivity:
            return false
        }
    }

    var shouldAutoRetry: Bool {
        switch self {
        case .networkError, .connectionTimeout, .uploadTimeout, .slowConnection:
            return true
        case .serverError(let statusCode, _):
            return statusCode >= 500
        case .serviceUnavailable, .technicalDifficulties, .temporaryServiceIssue:
            return true
        case .dependencyFailure, .thirdPartyServiceError:
            return true
        case .resourceExhausted, .operationTimeout:
            return true
        case .dataIntegrityError, .syncConflict:
            return true
        case .backgroundTaskExpired:
            return false
        default:
            return false
        }
    }

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
            return 300.0
        case .serviceUnavailable, .technicalDifficulties:
            return 15.0
        case .temporaryServiceIssue:
            return 30.0
        case .dependencyFailure, .thirdPartyServiceError:
            return 20.0
        case .resourceExhausted:
            return 60.0
        case .operationTimeout:
            return 10.0
        case .dataIntegrityError, .syncConflict:
            return 5.0
        default:
            return 0.0
        }
    }

    var maxRetryAttempts: Int {
        switch self {
        case .networkError, .connectionTimeout, .uploadTimeout:
            return 3
        case .slowConnection:
            return 2
        case .serverError(let statusCode, _):
            return statusCode >= 500 ? 2 : 0
        case .serviceUnavailable, .technicalDifficulties:
            return 2
        case .temporaryServiceIssue:
            return 1
        case .dependencyFailure, .thirdPartyServiceError:
            return 2
        case .resourceExhausted:
            return 1
        case .operationTimeout:
            return 3
        case .dataIntegrityError, .syncConflict:
            return 2
        default:
            return 0
        }
    }


    var errorCategory: ErrorCategory {
        switch self {
        case .networkError, .offlineError, .connectionTimeout, .slowConnection, .uploadTimeout:
            return .network
        case .unauthorized, .insufficientPermissions, .accountSuspended, .accountDeleted:
            return .authentication
        case .invalidInput, .validationFailed, .usernameNotAvailable:
            return .validation
        case .imageUploadFailed, .imageCompressionFailed, .imageSelectionFailed, .imageTooLarge, .unsupportedImageFormat:
            return .media
        case .serverError, .serviceUnavailable, .serverMaintenance, .technicalDifficulties:
            return .server
        case .rateLimitExceeded, .quotaExceeded, .resourceExhausted:
            return .quota
        case .contentModerated, .spamDetected, .maliciousContentDetected, .inappropriateContent:
            return .content
        case .privacyViolation, .termsViolation, .copyrightViolation, .businessRuleViolation:
            return .policy
        case .securityViolation, .fraudDetected, .suspiciousActivity:
            return .security
        case .dataCorrupted, .dataIntegrityError, .cacheCorrupted, .syncConflict:
            return .data
        case .versionMismatch, .platformNotSupported, .featureNotAvailable, .configurationError:
            return .compatibility
        default:
            return .system
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .invalidInput, .usernameNotAvailable, .imageSelectionFailed, .operationCancelled:
            return .low
        case .networkError, .offlineError, .uploadTimeout, .validationFailed:
            return .medium
        case .unauthorized, .serverError, .dataCorrupted, .securityViolation:
            return .high
        case .accountDeleted, .fraudDetected, .permanentServiceIssue, .maliciousContentDetected:
            return .critical
        default:
            return .medium
        }
    }

    var requiresImmediateAttention: Bool {
        switch self {
        case .accountSuspended, .accountDeleted, .securityViolation, .fraudDetected:
            return true
        case .maliciousContentDetected, .suspiciousActivity:
            return true
        case .permanentServiceIssue, .versionMismatch:
            return true
        default:
            return false
        }
    }

    var shouldLog: Bool {
        switch self {
        case .operationCancelled, .uploadCancelled:
            return false
        case .invalidInput, .usernameNotAvailable:
            return false
        default:
            return true
        }
    }

    var suggestedUserAction: UserAction {
        switch self {
        case .offlineError, .networkError, .connectionTimeout:
            return .checkConnection
        case .invalidInput, .validationFailed:
            return .correctInput
        case .unauthorized, .accountSuspended:
            return .contactSupport
        case .versionMismatch, .featureNotAvailable:
            return .updateApp
        case .deviceStorageFull:
            return .freeStorage
        case .rateLimitExceeded:
            return .waitAndRetry
        case .serverMaintenance, .serviceUnavailable:
            return .tryLater
        default:
            return .retry
        }
    }
}


enum ErrorCategory: String, CaseIterable {
    case network = "network"
    case authentication = "authentication"
    case validation = "validation"
    case media = "media"
    case server = "server"
    case quota = "quota"
    case content = "content"
    case policy = "policy"
    case security = "security"
    case data = "data"
    case compatibility = "compatibility"
    case system = "system"
}

enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

enum UserAction: String, CaseIterable {
    case retry = "retry"
    case checkConnection = "check_connection"
    case correctInput = "correct_input"
    case contactSupport = "contact_support"
    case updateApp = "update_app"
    case freeStorage = "free_storage"
    case waitAndRetry = "wait_and_retry"
    case tryLater = "try_later"
    case none = "none"
}

