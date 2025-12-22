import Foundation

// MARK: - LikeResponse

struct LikeResponse: Codable, Equatable {
    var isLiked: Bool
    var likeCount: Int

    // CodingKeys removed: APIClient uses .convertFromSnakeCase decoder strategy
    // which automatically converts is_liked -> isLiked, like_count -> likeCount
}

// MARK: - BookmarkResponse

struct BookmarkResponse: Codable, Equatable {
    var isBookmarked: Bool
    var bookmarkCount: Int

    // CodingKeys removed: APIClient uses .convertFromSnakeCase decoder strategy
    // which automatically converts is_bookmarked -> isBookmarked, bookmark_count -> bookmarkCount
}

// MARK: - EngagementStatus

struct EngagementStatus: Codable, Equatable {
    var isLiked: Bool
    var isBookmarked: Bool
    var likeCount: Int
    var bookmarkCount: Int
    var commentCount: Int

    enum CodingKeys: String, CodingKey {
        case isLiked = "is_liked"
        case isBookmarked = "is_bookmarked"
        case likeCount = "like_count"
        case bookmarkCount = "bookmark_count"
        case commentCount = "comment_count"
    }

    init(
        isLiked: Bool = false,
        isBookmarked: Bool = false,
        likeCount: Int = 0,
        bookmarkCount: Int = 0,
        commentCount: Int = 0
    ) {
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
        self.likeCount = likeCount
        self.bookmarkCount = bookmarkCount
        self.commentCount = commentCount
    }
}

// MARK: - CommentCreateRequest

struct CommentCreateRequest: Codable {
    var content: String
    var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case content
        case imageUrl = "image_url"
    }

    init(content: String, imageUrl: String? = nil) {
        self.content = content
        self.imageUrl = imageUrl
    }
}

// MARK: - CommentResponse

struct CommentResponse: Codable, Equatable {
    var comment: Comment
    var success: Bool
    var message: String?

    init(comment: Comment, success: Bool = true, message: String? = nil) {
        self.comment = comment
        self.success = success
        self.message = message
    }
}
