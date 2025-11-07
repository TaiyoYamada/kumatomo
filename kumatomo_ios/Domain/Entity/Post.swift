import Foundation

struct Post: Identifiable, Codable, Equatable {
    var id: Int
    var userId: Int?
    var shopId: Int?
    var content: String
    var imageUrl: String?
    var tags: [String]?
    var createdAt: Date?
    var updatedAt: Date?

    // 掲示板機能用の新しいプロパティ
    var category: CategoryType?
    var hashtags: [String]?
    var reactions: PostReactions?
    var userReaction: ReactionType?
    var commentCount: Int?
    var isBookmarked: Bool?
    var municipality: String?

    // 新しいエンゲージメント機能用プロパティ
    var likeCount: Int?
    var bookmarkCount: Int?
    var isLikedByCurrentUser: Bool?
    var isBookmarkedByCurrentUser: Bool?
    var comments: [Comment]?

    // 関連データ
    var user: User?
    var shop: Shop?
    var images: [PostImage]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case shopId = "shop_id"
        case content
        case imageUrl = "image_url"
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case category
        case hashtags
        case reactions
        case userReaction = "user_reaction"
        case commentCount = "comment_count"
        case isBookmarked = "is_bookmarked"
        case municipality
        case likeCount = "like_count"
        case bookmarkCount = "bookmark_count"
        case isLikedByCurrentUser = "is_liked_by_current_user"
        case isBookmarkedByCurrentUser = "is_bookmarked_by_current_user"
        case comments
        case user
        case shop
        case images
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decodeIfPresent(Int.self, forKey: .userId)
        shopId = try container.decodeIfPresent(Int.self, forKey: .shopId)
        content = (try? container.decode(String.self, forKey: .content)) ?? ""
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)

        // Dates are decoded via JSONDecoder.dateDecodingStrategy configured in the Data layer
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        // Additional properties
        category = try container.decodeIfPresent(CategoryType.self, forKey: .category)
        hashtags = try container.decodeIfPresent([String].self, forKey: .hashtags)
        reactions = try container.decodeIfPresent(PostReactions.self, forKey: .reactions)
        userReaction = try container.decodeIfPresent(ReactionType.self, forKey: .userReaction)
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount)
        isBookmarked = try container.decodeIfPresent(Bool.self, forKey: .isBookmarked)
        municipality = try container.decodeIfPresent(String.self, forKey: .municipality)

        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount)
        bookmarkCount = try container.decodeIfPresent(Int.self, forKey: .bookmarkCount)
        isLikedByCurrentUser = try container.decodeIfPresent(Bool.self, forKey: .isLikedByCurrentUser)
        isBookmarkedByCurrentUser = try container.decodeIfPresent(Bool.self, forKey: .isBookmarkedByCurrentUser)
        comments = try container.decodeIfPresent([Comment].self, forKey: .comments)

        user = try container.decodeIfPresent(User.self, forKey: .user)
        shop = try container.decodeIfPresent(Shop.self, forKey: .shop)
        images = try container.decodeIfPresent([PostImage].self, forKey: .images)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(shopId, forKey: .shopId)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)

        // 新しいプロパティ
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(hashtags, forKey: .hashtags)
        try container.encodeIfPresent(reactions, forKey: .reactions)
        try container.encodeIfPresent(userReaction, forKey: .userReaction)
        try container.encodeIfPresent(commentCount, forKey: .commentCount)
        try container.encodeIfPresent(isBookmarked, forKey: .isBookmarked)
        try container.encodeIfPresent(municipality, forKey: .municipality)

        // 新しいエンゲージメント機能用プロパティ
        try container.encodeIfPresent(likeCount, forKey: .likeCount)
        try container.encodeIfPresent(bookmarkCount, forKey: .bookmarkCount)
        try container.encodeIfPresent(isLikedByCurrentUser, forKey: .isLikedByCurrentUser)
        try container.encodeIfPresent(isBookmarkedByCurrentUser, forKey: .isBookmarkedByCurrentUser)
        try container.encodeIfPresent(comments, forKey: .comments)

        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(shop, forKey: .shop)
        try container.encodeIfPresent(images, forKey: .images)
    }
}

extension Post {
    init(id: Int = 0, userId: Int, content: String, shopId: Int? = nil, imageUrl: String? = nil, tags: [String]? = nil) {
        self.id = id
        self.userId = userId
        self.shopId = shopId
        self.content = content
        self.imageUrl = imageUrl
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
        self.shop = nil
        self.images = nil
    }

    mutating func updateContent(_ newContent: String) {
        self.content = newContent
        self.updatedAt = Date()
    }

    mutating func updateShop(_ newShop: Shop?) {
        self.shop = newShop
        self.shopId = newShop?.id
        self.updatedAt = Date()
    }

    mutating func updateTags(_ newTags: [String]?) {
        self.tags = newTags
        self.updatedAt = Date()
    }


    mutating func updateLikeStatus(isLiked: Bool, likeCount: Int) {
        self.isLikedByCurrentUser = isLiked
        self.likeCount = likeCount
        self.updatedAt = Date()
    }

    mutating func updateBookmarkStatus(isBookmarked: Bool, bookmarkCount: Int) {
        self.isBookmarkedByCurrentUser = isBookmarked
        self.bookmarkCount = bookmarkCount
        self.updatedAt = Date()
    }

    mutating func addComment(_ comment: Comment) {
        if comments == nil {
            comments = []
        }
        comments?.append(comment)
        commentCount = (commentCount ?? 0) + 1
        self.updatedAt = Date()
    }

    mutating func removeComment(withId commentId: Int) {
        comments?.removeAll { $0.id == commentId }
        commentCount = max(0, (commentCount ?? 0) - 1)
        self.updatedAt = Date()
    }

    var totalEngagementCount: Int {
        return (likeCount ?? 0) + (bookmarkCount ?? 0) + (commentCount ?? 0)
    }

    var isEngagedByCurrentUser: Bool {
        return (isLikedByCurrentUser == true) || (isBookmarkedByCurrentUser == true)
    }

    var engagementSummary: String {
        var parts: [String] = []

        if let likes = likeCount, likes > 0 {
            parts.append("\(likes)いいね")
        }

        if let comments = commentCount, comments > 0 {
            parts.append("\(comments)コメント")
        }

        if let bookmarks = bookmarkCount, bookmarks > 0 {
            parts.append("\(bookmarks)ブックマーク")
        }

        return parts.joined(separator: " • ")
    }
}
