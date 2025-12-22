import Foundation

/// @mockable
protocol PostRepository {
    func fetchAllPosts(page: Int?, limit: Int?) async throws -> [Post]
    func fetchUserPosts(userId: Int, page: Int?, limit: Int?) async throws -> [Post]
    func fetchMunicipalityPosts(municipality: String, page: Int?, limit: Int?) async throws -> [Post]
    func fetchFollowingPosts(page: Int?, limit: Int?) async throws -> [Post]

    func createPost(userId: Int, content: String, imageUrl: String?, tags: [String]) async throws -> Post
    func createPostWithMultipleImages(userId: Int, content: String, imageUrls: [String], tags: [String]) async throws
        -> Post

    func updatePost(postId: Int, content: String, tags: [String]) async throws -> Post
    func deletePost(postId: Int) async throws
    func fetchPost(postId: Int) async throws -> Post

    func toggleReaction(postId: Int, reactionType: ReactionType) async throws
        -> (reactions: PostReactions, userReaction: ReactionType?)
    func toggleBookmark(postId: Int) async throws -> Bool

    func fetchAllPostsWithCache(page: Int, limit: Int, useCache: Bool) async throws -> [Post]
    func fetchMunicipalityPostsWithCache(municipality: String, page: Int, limit: Int, useCache: Bool) async throws
        -> [Post]
    func fetchFollowingPostsWithCache(page: Int, limit: Int, useCache: Bool) async throws -> [Post]
}
