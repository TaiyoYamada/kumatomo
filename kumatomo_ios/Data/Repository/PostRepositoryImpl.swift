import Foundation

// Data adapter wrapping PostAPIService, conforming to Domain's PostRepository
final class PostRepositoryImpl: PostRepository {
    private let service: PostAPIService

    init(service: PostAPIService = .shared) {
        self.service = service
    }

    func fetchAllPosts(page: Int?, limit: Int?) async throws -> [Post] {
        try await service.fetchAllPosts(page: page ?? 1, limit: limit ?? 20)
    }

    func fetchUserPosts(userId: Int, page: Int?, limit: Int?) async throws -> [Post] {
        try await service.fetchUserPosts(userId: userId, page: page ?? 1, limit: limit ?? 20)
    }

    func fetchMunicipalityPosts(municipality: String, page: Int?, limit: Int?) async throws -> [Post] {
        try await service.fetchMunicipalityPosts(municipality: municipality, page: page ?? 1, limit: limit ?? 20)
    }

    func fetchFollowingPosts(page: Int?, limit: Int?) async throws -> [Post] {
        try await service.fetchFollowingPosts(page: page ?? 1, limit: limit ?? 20)
    }

    func createPost(userId: Int, content: String, imageUrl: String?, tags: [String]) async throws -> Post {
        try await service.createPost(userId: userId, content: content, imageUrl: imageUrl, tags: tags)
    }

    func createPostWithMultipleImages(userId: Int, content: String, shopId: Int?, imageUrls: [String], tags: [String]) async throws -> Post {
        try await service.createPostWithMultipleImages(userId: userId, content: content, shopId: shopId, imageUrls: imageUrls, tags: tags)
    }

    func updatePost(postId: Int, content: String, shopId: Int?, tags: [String]) async throws -> Post {
        try await service.updatePost(postId: postId, content: content, shopId: shopId, tags: tags)
    }

    func deletePost(postId: Int) async throws {
        try await service.deletePost(postId: postId)
    }

    func fetchPost(postId: Int) async throws -> Post {
        try await service.fetchPost(postId: postId)
    }

    func toggleReaction(postId: Int, reactionType: ReactionType) async throws -> (reactions: PostReactions, userReaction: ReactionType?) {
        try await service.toggleReaction(postId: postId, reactionType: reactionType)
    }

    func toggleBookmark(postId: Int) async throws -> Bool {
        try await service.toggleBookmark(postId: postId)
    }

    func fetchAllPostsWithCache(page: Int, limit: Int, useCache: Bool) async throws -> [Post] {
        try await service.fetchAllPostsWithCache(page: page, limit: limit, useCache: useCache)
    }

    func fetchMunicipalityPostsWithCache(municipality: String, page: Int, limit: Int, useCache: Bool) async throws -> [Post] {
        try await service.fetchMunicipalityPostsWithCache(municipality: municipality, page: page, limit: limit, useCache: useCache)
    }

    func fetchFollowingPostsWithCache(page: Int, limit: Int, useCache: Bool) async throws -> [Post] {
        try await service.fetchFollowingPostsWithCache(page: page, limit: limit, useCache: useCache)
    }
}
