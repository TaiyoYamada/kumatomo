import Foundation

// MARK: - UpdateProfileUseCaseProtocol

/// プロフィール更新を行うUseCaseのProtocol
protocol UpdateProfileUseCaseProtocol: Sendable {
    /// プロフィールを更新
    /// - Parameter user: 更新するユーザー情報
    /// - Returns: 更新されたユーザー情報
    func execute(user: User) async throws -> User
}
