import Foundation

// MARK: - FetchFollowingUseCaseProtocol

/// フォロー中ユーザー一覧取得ユースケースプロトコル
protocol FetchFollowingUseCaseProtocol: Sendable {
    func execute(userId: Int, page: Int, limit: Int) async throws -> [FollowUser]
}

// MARK: - FetchFollowingUseCase

/// フォロー中ユーザー一覧取得ユースケース
struct FetchFollowingUseCase: FetchFollowingUseCaseProtocol {
    private let repository: FollowRepositoryProtocol

    init(repository: FollowRepositoryProtocol) {
        self.repository = repository
    }

    func execute(userId: Int, page: Int = 1, limit: Int = 20) async throws -> [FollowUser] {
        try await repository.fetchFollowing(userId: userId, page: page, limit: limit)
    }
}
