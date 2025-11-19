import Foundation
import SwiftUI
import Combine
import Observation

@MainActor
@Observable
class ErrorManager {
    static let shared = ErrorManager()

    var currentError: AppError?
    var errorHistory: [AppError] = []
    var isShowingError = false

    private var cancellables = Set<AnyCancellable>()
    private let maxHistoryCount = 50

    private init() {
        setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        NotificationCenter.default.publisher(for: .NetworkConnectivityChanged)
            .compactMap { $0.userInfo?["isConnected"] as? Bool }
            .sink { [weak self] isConnected in
                // ネットワーク復帰時はネットワーク系のエラー表示を明示的に閉じる
                if isConnected, let error = self?.currentError, error.errorType == .network {
                    self?.dismissError()
                }
            }
            .store(in: &cancellables)
    }


    func handleError(_ error: Error, context: String = "") {
        let appError = AppError.from(error, context: context)

        logError(appError)

        addToHistory(appError)

        if appError.shouldShowToUser {
            showError(appError)
        }
    }

    func handleError(_ error: AppError, context: String = "") {
        logError(error)

        addToHistory(error)

        if error.shouldShowToUser {
            showError(error)
        }
    }

    func handleAPIError(_ error: APIError, context: String = "") {
        let appError = AppError.apiError(error, context: context)
        handleError(appError)
    }

    func showError(_ error: AppError) {
        currentError = error
        isShowingError = true
    }

    func dismissError() {
        currentError = nil
        isShowingError = false
    }

    func retryLastOperation() async {
        guard let error = currentError,
              let retryAction = error.retryAction else {
            return
        }

        do {
            try await retryAction()
            dismissError()
        } catch {
            handleError(error, context: "Retry failed")
        }
    }


    private func addToHistory(_ error: AppError) {
        errorHistory.insert(error, at: 0)

        if errorHistory.count > maxHistoryCount {
            errorHistory = Array(errorHistory.prefix(maxHistoryCount))
        }
    }

    func clearHistory() {
        errorHistory.removeAll()
    }


    private func logError(_ error: AppError) {
        let logMessage = """
        [ERROR] \(error.title)
        Message: \(error.message)
        Context: \(error.context)
        Type: \(error.errorType)
        Timestamp: \(error.timestamp)
        Recovery: \(error.recoverySuggestion ?? "None")
        Retryable: \(error.isRetryable)
        """

        print(logMessage)

        #if DEBUG
        if let underlyingError = error.underlyingError {
            print("Underlying error: \(underlyingError)")
        }
        #endif
    }


    func getErrorStatistics() -> ErrorStatistics {
        let totalErrors = errorHistory.count
        let networkErrors = errorHistory.filter { $0.errorType == .network }.count
        let apiErrors = errorHistory.filter { $0.errorType == .api }.count
        let validationErrors = errorHistory.filter { $0.errorType == .validation }.count

        return ErrorStatistics(
            totalErrors: totalErrors,
            networkErrors: networkErrors,
            apiErrors: apiErrors,
            validationErrors: validationErrors,
            lastError: errorHistory.first
        )
    }
}


struct AppError: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let context: String
    let errorType: ErrorType
    let timestamp: Date
    let recoverySuggestion: String?
    let isRetryable: Bool
    let shouldShowToUser: Bool
    let underlyingError: Error?
    let retryAction: (() async throws -> Void)?

    enum ErrorType {
        case network
        case api
        case validation
        case authentication
        case authorization
        case fileSystem
        case unknown
    }

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }


    static func from(_ error: Error, context: String = "") -> AppError {
        if let apiError = error as? APIError {
            return AppError.apiError(apiError, context: context)
        }

        if let urlError = error as? URLError {
            return AppError.networkError(urlError, context: context)
        }

        if let authError = error as? AuthError {
            return AppError.authenticationError(authError, context: context)
        }

        return AppError.unknownError(error, context: context)
    }

    static func apiError(_ error: APIError, context: String = "") -> AppError {
        return AppError(
            title: "APIエラー",
            message: error.localizedDescription,
            context: context,
            errorType: .api,
            timestamp: Date(),
            recoverySuggestion: error.recoverySuggestion,
            isRetryable: isRetryableAPIError(error),
            shouldShowToUser: true,
            underlyingError: error,
            retryAction: nil
        )
    }

    static func networkError(_ error: URLError, context: String = "") -> AppError {
        return AppError(
            title: "ネットワークエラー",
            message: getNetworkErrorMessage(error),
            context: context,
            errorType: .network,
            timestamp: Date(),
            recoverySuggestion: getNetworkRecoverySuggestion(error),
            isRetryable: shouldRetryNetworkRequest(error),
            shouldShowToUser: true,
            underlyingError: error,
            retryAction: nil
        )
    }

    private static func getNetworkErrorMessage(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "インターネットに接続されていません"
        case .timedOut:
            return "通信がタイムアウトしました"
        case .cannotConnectToHost:
            return "サーバーに接続できません"
        case .networkConnectionLost:
            return "ネットワーク接続が失われました"
        default:
            return "ネットワークエラーが発生しました"
        }
    }

    private static func shouldRetryNetworkRequest(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet:
            return true
        case .cannotConnectToHost:
            return true
        default:
            return false
        }
    }

    static func authenticationError(_ error: AuthError, context: String = "") -> AppError {
        return AppError(
            title: "認証エラー",
            message: error.localizedDescription,
            context: context,
            errorType: .authentication,
            timestamp: Date(),
            recoverySuggestion: "ログインし直してください",
            isRetryable: false,
            shouldShowToUser: true,
            underlyingError: error,
            retryAction: nil
        )
    }

    static func validationError(_ message: String, context: String = "") -> AppError {
        return AppError(
            title: "入力エラー",
            message: message,
            context: context,
            errorType: .validation,
            timestamp: Date(),
            recoverySuggestion: "入力内容を確認してください",
            isRetryable: false,
            shouldShowToUser: true,
            underlyingError: nil,
            retryAction: nil
        )
    }

    static func unknownError(_ error: Error, context: String = "") -> AppError {
        return AppError(
            title: "予期しないエラー",
            message: error.localizedDescription,
            context: context,
            errorType: .unknown,
            timestamp: Date(),
            recoverySuggestion: "アプリを再起動してください",
            isRetryable: false,
            shouldShowToUser: true,
            underlyingError: error,
            retryAction: nil
        )
    }


    private static func isRetryableAPIError(_ error: APIError) -> Bool {
        switch error {
        case .networkError, .timeout, .serverError:
            return true
        case .unauthorized, .forbidden, .notFound, .decodingError, .encodingError, .invalidURL, .invalidResponse, .userNotFound:
            return false
        case .rateLimitExceeded:
            return true
        case .apiError:
            return false
        case .unknownError:
            return false
        }
    }

    private static func getNetworkRecoverySuggestion(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "インターネット接続を確認してください"
        case .timedOut:
            return "通信環境を確認して再試行してください"
        case .cannotConnectToHost:
            return "サーバーの状態を確認してください"
        default:
            return "ネットワーク接続を確認してください"
        }
    }
}


struct ErrorStatistics {
    let totalErrors: Int
    let networkErrors: Int
    let apiErrors: Int
    let validationErrors: Int
    let lastError: AppError?

    var networkErrorRate: Double {
        guard totalErrors > 0 else { return 0 }
        return Double(networkErrors) / Double(totalErrors)
    }

    var apiErrorRate: Double {
        guard totalErrors > 0 else { return 0 }
        return Double(apiErrors) / Double(totalErrors)
    }
}


class ErrorRetryManager {
    private var retryAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3

    func canRetry(for errorId: String) -> Bool {
        let attempts = retryAttempts[errorId] ?? 0
        return attempts < maxRetryAttempts
    }

    func incrementRetryCount(for errorId: String) {
        retryAttempts[errorId] = (retryAttempts[errorId] ?? 0) + 1
    }

    func resetRetryCount(for errorId: String) {
        retryAttempts.removeValue(forKey: errorId)
    }

    func getRetryDelay(for errorId: String) -> TimeInterval {
        let attempts = retryAttempts[errorId] ?? 0
        return min(pow(2.0, Double(attempts)), 30.0)
    }
}
