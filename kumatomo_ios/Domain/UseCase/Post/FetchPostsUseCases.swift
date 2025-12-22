import Foundation

// MARK: - FetchAllPostsUseCase

protocol FetchAllPostsUseCase { func execute(page: Int?, limit: Int?) async throws -> [Post] }

// MARK: - FetchUserPostsUseCase

protocol FetchUserPostsUseCase { func execute(userId: Int, page: Int?, limit: Int?) async throws -> [Post] }

// MARK: - FetchMunicipalityPostsUseCase

protocol FetchMunicipalityPostsUseCase {
    func execute(municipality: String, page: Int?, limit: Int?) async throws -> [Post]
}

// MARK: - FetchFollowingPostsUseCase

protocol FetchFollowingPostsUseCase { func execute(page: Int?, limit: Int?) async throws -> [Post] }

// MARK: - FetchPostUseCase

protocol FetchPostUseCase { func execute(postId: Int) async throws -> Post }

// MARK: - FetchAllPostsUseCaseImpl

final class FetchAllPostsUseCaseImpl: FetchAllPostsUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(page: Int?, limit: Int?) async throws -> [Post] { try await repository.fetchAllPosts(
        page: page,
        limit: limit
    ) }
}

// MARK: - FetchUserPostsUseCaseImpl

final class FetchUserPostsUseCaseImpl: FetchUserPostsUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(userId: Int, page: Int?, limit: Int?) async throws -> [Post] { try await repository.fetchUserPosts(
        userId: userId,
        page: page,
        limit: limit
    ) }
}

// MARK: - FetchMunicipalityPostsUseCaseImpl

final class FetchMunicipalityPostsUseCaseImpl: FetchMunicipalityPostsUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(
        municipality: String,
        page: Int?,
        limit: Int?
    ) async throws -> [Post] { try await repository.fetchMunicipalityPosts(
        municipality: municipality,
        page: page,
        limit: limit
    ) }
}

// MARK: - FetchFollowingPostsUseCaseImpl

final class FetchFollowingPostsUseCaseImpl: FetchFollowingPostsUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(page: Int?, limit: Int?) async throws -> [Post] { try await repository.fetchFollowingPosts(
        page: page,
        limit: limit
    ) }
}

// MARK: - FetchPostUseCaseImpl

final class FetchPostUseCaseImpl: FetchPostUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(postId: Int) async throws -> Post { try await repository.fetchPost(postId: postId) }
}
