import Foundation

// MARK: - CheckUsernameAvailabilityUseCaseProtocol

/// ユーザーネームの利用可能性をチェックするUseCaseのProtocol
protocol CheckUsernameAvailabilityUseCaseProtocol: Sendable {
    /// ユーザーネームが利用可能かチェック
    /// - Parameter username: チェックするユーザーネーム
    /// - Returns: 利用可能な場合はtrue
    func execute(username: String) async throws -> Bool
}
