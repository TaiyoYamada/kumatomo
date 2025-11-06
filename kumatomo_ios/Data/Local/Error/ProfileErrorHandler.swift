import Foundation
import SwiftUI
import Combine
import Observation


@MainActor
@Observable
class ProfileErrorHandler {
    static let shared = ProfileErrorHandler()

    var currentError: ProfileError?
    var showErrorAlert = false
    var showRetryAlert = false
    var isRetrying = false
    var retryCount = 0

    private var retryTimer: Timer?
    private var retryAction: (() async -> Void)?
    private let networkMonitor = NetworkMonitor.shared

    private init() {}


    func handleError(_ error: Error, retryAction: (() async -> Void)? = nil) {
        let profileError = convertToProfileError(error)
        self.currentError = profileError
        self.retryAction = retryAction

        logError(profileError)

        if profileError.shouldAutoRetry && retryCount < profileError.maxRetryAttempts {
            handleAutoRetry(profileError)
        } else if profileError.isRecoverable && retryAction != nil {
            showRetryAlert = true
        } else {
            showErrorAlert = true
        }
    }


    private func convertToProfileError(_ error: Error) -> ProfileError {
        if let profileError = error as? ProfileError {
            return profileError
        }

        if let urlError = error as? URLError {
            return convertURLError(urlError)
        }

        if let imageError = error as? ImageUploadError {
            return convertImageError(imageError)
        }

        if !networkMonitor.isConnected {
            return .offlineError
        }

        return .networkError(error)
    }


    private func convertURLError(_ urlError: URLError) -> ProfileError {
        switch urlError.code {
        case .notConnectedToInternet, .dataNotAllowed:
            return .offlineError
        case .timedOut:
            return .connectionTimeout
        case .networkConnectionLost:
            return .slowConnection
        case .cannotConnectToHost, .cannotFindHost:
            return .networkError(urlError)
        default:
            return .networkError(urlError)
        }
    }


    private func convertImageError(_ imageError: ImageUploadError) -> ProfileError {
        switch imageError {
        case .imageConversionFailed:
            return .imageCompressionFailed
        case .fileSizeExceeded(let currentSize, let maxSize):
            return .imageTooLarge(maxSize: maxSize / (1024 * 1024))
        case .unsupportedImageFormat:
            return .unsupportedImageFormat
        case .uploadFailed(let reason):
            return .imageUploadFailed(NSError(domain: "ImageUpload", code: 0, userInfo: [NSLocalizedDescriptionKey: reason]))
        case .networkError(let error):
            return .networkError(error)
        case .serverError(let statusCode, let message):
            return .serverError(statusCode: statusCode, message: message)
        case .timeout:
            return .uploadTimeout
        case .imageTooLarge(_, _, let maxWidth, let maxHeight):
            return .imageTooLarge(maxSize: 10)
        default:
            return .imageUploadFailed(NSError(domain: "ImageUpload", code: 0, userInfo: [NSLocalizedDescriptionKey: imageError.localizedDescription]))
        }
    }


    private func handleAutoRetry(_ error: ProfileError) {
        guard let retryAction = retryAction else {
            showErrorAlert = true
            return
        }

        isRetrying = true
        retryCount += 1

        let delay = error.retryDelay

        retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.executeRetry(retryAction)
            }
        }
    }

    private func executeRetry(_ action: @escaping () async -> Void) async {
        isRetrying = false
        retryTimer?.invalidate()
        retryTimer = nil

        await action()
        retryCount = 0
        clearError()
    }


    func retryLastAction() async {
        guard let retryAction = retryAction else { return }

        showRetryAlert = false
        isRetrying = true

        await retryAction()
        retryCount = 0
        clearError()

        isRetrying = false
    }


    func clearError() {
        currentError = nil
        showErrorAlert = false
        showRetryAlert = false
        isRetrying = false
        retryCount = 0
        retryAction = nil
        retryTimer?.invalidate()
        retryTimer = nil
    }

    func dismissError() {
        showErrorAlert = false
        showRetryAlert = false
    }


    private func logError(_ error: ProfileError) {
        let errorInfo = [
            "Error": String(describing: error),
            "Description": error.errorDescription ?? "No description",
            "Recovery": error.recoverySuggestion ?? "No suggestion",
            "Recoverable": String(error.isRecoverable),
            "AutoRetry": String(error.shouldAutoRetry),
            "RetryCount": String(retryCount),
            "NetworkStatus": networkMonitor.isConnected ? "Connected" : "Offline"
        ]

        print("🚨 ProfileError: \(errorInfo)")

    }


    func getDisplayMessage(for error: ProfileError) -> String {
        var message = error.errorDescription ?? "不明なエラーが発生しました"

        if !networkMonitor.isConnected {
            message += "\n\nインターネット接続を確認してください。"
        } else if networkMonitor.shouldLimitDataUsage() {
            message += "\n\n現在、制限のあるネットワーク接続を使用しています。"
        }

        return message
    }

    func getRecoveryMessage(for error: ProfileError) -> String? {
        return error.recoverySuggestion
    }


    func handleValidationErrors(_ errors: [String]) {
        if !errors.isEmpty {
            let validationError = ProfileError.validationFailed(errors)
            handleError(validationError)
        }
    }


    func handleImageUploadError(_ error: Error, imageType: String) {
        let profileError = convertToProfileError(error)

        let contextualError: ProfileError
        switch profileError {
        case .imageUploadFailed(let originalError):
            contextualError = .imageUploadFailed(NSError(
                domain: "ProfileImageUpload",
                code: 0,
                userInfo: [
                    NSLocalizedDescriptionKey: "\(imageType)のアップロードに失敗しました",
                    NSUnderlyingErrorKey: originalError
                ]
            ))
        default:
            contextualError = profileError
        }

        handleError(contextualError)
    }


    func handleNetworkError(_ error: Error, operation: String) {
        if !networkMonitor.isConnected {
            handleError(ProfileError.offlineError)
            return
        }

        let networkError = ProfileError.networkError(NSError(
            domain: "ProfileNetworkOperation",
            code: 0,
            userInfo: [
                NSLocalizedDescriptionKey: "\(operation)中にネットワークエラーが発生しました",
                NSUnderlyingErrorKey: error
            ]
        ))

        handleError(networkError)
    }
}


extension ProfileErrorHandler {

    func errorAlert() -> Alert {
        guard let error = currentError else {
            return Alert(title: Text("エラー"))
        }

        let message = getDisplayMessage(for: error)
        let recovery = getRecoveryMessage(for: error)

        if error.isRecoverable && retryAction != nil {
            return Alert(
                title: Text("エラーが発生しました"),
                message: Text(message + (recovery != nil ? "\n\n\(recovery!)" : "")),
                primaryButton: .default(Text("再試行")) {
                    Task {
                        await self.retryLastAction()
                    }
                },
                secondaryButton: .cancel(Text("キャンセル")) {
                    self.clearError()
                }
            )
        } else {
            return Alert(
                title: Text("エラーが発生しました"),
                message: Text(message + (recovery != nil ? "\n\n\(recovery!)" : "")),
                dismissButton: .default(Text("OK")) {
                    self.clearError()
                }
            )
        }
    }

    func retryAlert() -> Alert {
        Alert(
            title: Text("再試行しますか？"),
            message: Text("操作を再試行しますか？"),
            primaryButton: .default(Text("再試行")) {
                Task {
                    await self.retryLastAction()
                }
            },
            secondaryButton: .cancel(Text("キャンセル")) {
                self.clearError()
            }
        )
    }
}
