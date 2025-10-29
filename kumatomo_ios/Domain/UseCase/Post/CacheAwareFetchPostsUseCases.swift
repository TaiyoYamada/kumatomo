import Foundation

protocol FetchAllPostsWithCacheUseCase { func execute(page: Int, limit: Int, useCache: Bool) async throws -> [Post] }
protocol FetchMunicipalityPostsWithCacheUseCase { func execute(municipality: String, page: Int, limit: Int, useCache: Bool) async throws -> [Post] }
protocol FetchFollowingPostsWithCacheUseCase { func execute(page: Int, limit: Int, useCache: Bool) async throws -> [Post] }

final class FetchAllPostsWithCacheUseCaseImpl: FetchAllPostsWithCacheUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(page: Int, limit: Int, useCache: Bool) async throws -> [Post] {
        try await repository.fetchAllPostsWithCache(page: page, limit: limit, useCache: useCache)
    }
}

final class FetchMunicipalityPostsWithCacheUseCaseImpl: FetchMunicipalityPostsWithCacheUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(municipality: String, page: Int, limit: Int, useCache: Bool) async throws -> [Post] {
        try await repository.fetchMunicipalityPostsWithCache(municipality: municipality, page: page, limit: limit, useCache: useCache)
    }
}

final class FetchFollowingPostsWithCacheUseCaseImpl: FetchFollowingPostsWithCacheUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(page: Int, limit: Int, useCache: Bool) async throws -> [Post] {
        try await repository.fetchFollowingPostsWithCache(page: page, limit: limit, useCache: useCache)
    }
}

