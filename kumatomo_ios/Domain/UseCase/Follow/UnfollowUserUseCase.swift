import Foundation

// MARK: - UnfollowUserUseCaseProtocol

/// フォロー解除ユースケースプロトコル
protocol UnfollowUserUseCaseProtocol: Sendable {
    func execute(userId: Int) async throws
}

// MARK: - UnfollowUserUseCase

/// フォロー解除ユースケース
struct UnfollowUserUseCase: UnfollowUserUseCaseProtocol {
    private let repository: FollowRepositoryProtocol

    init(repository: FollowRepositoryProtocol) {
        self.repository = repository
    }

    func execute(userId: Int) async throws {
        try await repository.unfollowUser(userId: userId)
    }
}
