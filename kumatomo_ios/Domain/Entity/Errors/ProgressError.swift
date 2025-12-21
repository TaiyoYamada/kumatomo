import Foundation

// MARK: - ProgressError

enum ProgressError: LocalizedError {
    case operationCancelled(reason: String)
    case operationTimeout
    case operationFailed(underlying: Error)
    case invalidOperation

    var errorDescription: String? {
        switch self {
        case let .operationCancelled(reason):
            return "操作がキャンセルされました: \(reason)"
        case .operationTimeout:
            return "操作がタイムアウトしました"
        case let .operationFailed(error):
            return "操作が失敗しました: \(error.localizedDescription)"
        case .invalidOperation:
            return "無効な操作です"
        }
    }
}
