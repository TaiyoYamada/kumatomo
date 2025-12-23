import Foundation

// MARK: - FollowUserUseCaseProtocol

/// ユーザーをフォローするユースケースプロトコル
protocol FollowUserUseCaseProtocol: Sendable {
    func execute(userId: Int) async throws
}

// MARK: - FollowUserUseCase

/// ユーザーをフォローするユースケース
struct FollowUserUseCase: FollowUserUseCaseProtocol {
    private let repository: FollowRepositoryProtocol

    init(repository: FollowRepositoryProtocol) {
        self.repository = repository
    }

    func execute(userId: Int) async throws {
        try await repository.followUser(userId: userId)
    }
}
