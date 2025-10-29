import Foundation

protocol FetchBookmarkedPostsUseCase {
    func execute(page: Int?, limit: Int?) async throws -> [Post]
}

final class FetchBookmarkedPostsUseCaseImpl: FetchBookmarkedPostsUseCase {
    private let repository: EngagementRepository

    init(repository: EngagementRepository) {
        self.repository = repository
    }

    func execute(page: Int?, limit: Int?) async throws -> [Post] {
        try await repository.fetchBookmarkedPosts(page: page, limit: limit)
    }
}

