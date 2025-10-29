import Foundation

protocol FetchLikedPostsUseCase {
    func execute(page: Int?, limit: Int?) async throws -> [Post]
}

final class FetchLikedPostsUseCaseImpl: FetchLikedPostsUseCase {
    private let repository: EngagementRepository

    init(repository: EngagementRepository) {
        self.repository = repository
    }

    func execute(page: Int?, limit: Int?) async throws -> [Post] {
        try await repository.fetchLikedPosts(page: page, limit: limit)
    }
}

