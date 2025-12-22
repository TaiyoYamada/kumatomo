import Foundation

// MARK: - ValidationResult

/// バリデーション結果を表すenum
enum ValidationResult: Equatable, Sendable {
    case valid
    case invalid(message: String)

    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }

    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case let .invalid(message):
            return message
        }
    }
}
