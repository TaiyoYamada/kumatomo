import Foundation

protocol FetchAllPostsUseCase { func execute(page: Int?, limit: Int?) async throws -> [Post] }
protocol FetchUserPostsUseCase { func execute(userId: Int, page: Int?, limit: Int?) async throws -> [Post] }
protocol FetchMunicipalityPostsUseCase { func execute(municipality: String, page: Int?, limit: Int?) async throws -> [Post] }
protocol FetchFollowingPostsUseCase { func execute(page: Int?, limit: Int?) async throws -> [Post] }
protocol FetchPostUseCase { func execute(postId: Int) async throws -> Post }

final class FetchAllPostsUseCaseImpl: FetchAllPostsUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(page: Int?, limit: Int?) async throws -> [Post] { try await repository.fetchAllPosts(page: page, limit: limit) }
}

final class FetchUserPostsUseCaseImpl: FetchUserPostsUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(userId: Int, page: Int?, limit: Int?) async throws -> [Post] { try await repository.fetchUserPosts(userId: userId, page: page, limit: limit) }
}

final class FetchMunicipalityPostsUseCaseImpl: FetchMunicipalityPostsUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(municipality: String, page: Int?, limit: Int?) async throws -> [Post] { try await repository.fetchMunicipalityPosts(municipality: municipality, page: page, limit: limit) }
}

final class FetchFollowingPostsUseCaseImpl: FetchFollowingPostsUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(page: Int?, limit: Int?) async throws -> [Post] { try await repository.fetchFollowingPosts(page: page, limit: limit) }
}

final class FetchPostUseCaseImpl: FetchPostUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(postId: Int) async throws -> Post { try await repository.fetchPost(postId: postId) }
}

