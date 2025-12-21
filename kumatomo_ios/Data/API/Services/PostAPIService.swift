import Foundation

// MARK: - PostAPIService

/// 投稿APIサービス（Alamofire + APIClient使用）
final class PostAPIService {
    static let shared = PostAPIService()

    private let client = APIClient.shared

    private init() {}

    // MARK: - 投稿取得

    /// 全投稿を取得（ページネーション対応）
    func fetchAllPosts(page: Int? = nil, limit: Int? = nil) async throws -> [Post] {
        try await client.get(PostEndpoint.fetchAll(page: page, limit: limit))
    }

    /// 投稿詳細を取得
    func fetchPost(postId: Int) async throws -> Post {
        try await client.get(PostEndpoint.fetchPost(id: postId))
    }

    /// ユーザーの投稿を取得
    func fetchUserPosts(userId: Int, page: Int = 1, limit: Int = 20) async throws -> [Post] {
        try await client.get(PostEndpoint.fetchUserPosts(userId: userId, page: page, limit: limit))
    }

    /// 市町村別投稿を取得
    func fetchMunicipalityPosts(municipality: String, page: Int = 1, limit: Int = 20) async throws -> [Post] {
        try await client.get(PostEndpoint.fetchMunicipalityPosts(municipality: municipality, page: page, limit: limit))
    }

    /// フォロー中ユーザーの投稿を取得
    func fetchFollowingPosts(page: Int = 1, limit: Int = 20) async throws -> [Post] {
        try await client.get(PostEndpoint.fetchFollowingPosts(page: page, limit: limit))
    }

    // MARK: - 投稿作成・更新・削除

    /// 投稿を作成（複数画像対応）
    func createPostWithMultipleImages(
        userId: Int,
        content: String,
        imageUrls: [String],
        tags: [String] = []
    ) async throws -> Post {
        try await client.post(PostEndpoint.create(userId: userId, content: content, imageUrls: imageUrls, tags: tags))
    }

    /// 投稿を作成（単一画像）
    func createPost(userId: Int, content: String, imageUrl: String? = nil, tags: [String] = []) async throws -> Post {
        let imageUrls = imageUrl.map { [$0] } ?? []
        return try await createPostWithMultipleImages(
            userId: userId,
            content: content,
            imageUrls: imageUrls,
            tags: tags
        )
    }

    /// 投稿を更新
    func updatePost(postId: Int, content: String, tags: [String] = []) async throws -> Post {
        try await client.put(PostEndpoint.update(postId: postId, content: content, tags: tags))
    }

    /// 投稿を削除
    func deletePost(postId: Int) async throws {
        try await client.delete(PostEndpoint.delete(postId: postId))
    }

    // MARK: - エンゲージメント

    /// リアクションをトグル
    func toggleReaction(
        postId: Int,
        reactionType: ReactionType
    ) async throws -> (reactions: PostReactions, userReaction: ReactionType?) {
        let response: ToggleReactionResponse = try await client.post(
            PostEndpoint.toggleReaction(postId: postId, reactionType: reactionType.rawValue)
        )
        return (response.reactions, response.userReaction)
    }

    /// ブックマークをトグル
    func toggleBookmark(postId: Int) async throws -> Bool {
        let response: PostBookmarkResponse = try await client.post(PostEndpoint.toggleBookmark(postId: postId))
        return response.isBookmarked
    }
}

// MARK: - ToggleReactionResponse

private struct ToggleReactionResponse: Decodable {
    let reactions: PostReactions
    let userReaction: ReactionType?

    enum CodingKeys: String, CodingKey {
        case reactions
        case userReaction = "user_reaction"
    }
}

// MARK: - PostBookmarkResponse

private struct PostBookmarkResponse: Decodable {
    let isBookmarked: Bool

    enum CodingKeys: String, CodingKey {
        case isBookmarked = "is_bookmarked"
    }
}
