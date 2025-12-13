import Foundation
@testable import kumatomo

// MARK: - UserFixtures

enum UserFixtures {
    static let testUser = User(
        id: 1,
        email: "test@example.com",
        name: "テストユーザー",
        username: "testuser",
        profileImageURL: nil,
        coverImageURL: nil,
        bio: "テスト用プロフィール",
        location: "熊本県",
        birthday: "1990-01-01",
        postCount: 10,
        followingCount: 5,
        followersCount: 20,
        hasCompletedSetup: true,
        createdAt: Date(),
        isVerified: false,
        joinedDate: "2024-01-01"
    )

    static let newUser = User(
        id: 2,
        email: "new@example.com",
        name: nil,
        username: nil,
        profileImageURL: nil,
        coverImageURL: nil,
        bio: nil,
        location: nil,
        birthday: nil,
        postCount: 0,
        followingCount: 0,
        followersCount: 0,
        hasCompletedSetup: false,
        createdAt: Date(),
        isVerified: false,
        joinedDate: nil
    )
}

// MARK: - PostFixtures

enum PostFixtures {
    static func createPost(
        id: Int = 1,
        userId: Int = 1,
        content: String = "テスト投稿"
    ) -> Post {
        Post(id: id, userId: userId, content: content)
    }

    static let samplePosts: [Post] = [
        Post(id: 1, userId: 1, content: "投稿1"),
        Post(id: 2, userId: 1, content: "投稿2"),
        Post(id: 3, userId: 2, content: "投稿3"),
    ]

    static let emptyPosts: [Post] = []
}

// MARK: - TestError

enum TestError: Error, Equatable {
    case network
    case unauthorized
    case notFound
    case serverError(code: Int)

    var localizedDescription: String {
        switch self {
        case .network:
            return "ネットワークエラー"
        case .unauthorized:
            return "認証エラー"
        case .notFound:
            return "見つかりません"
        case let .serverError(code):
            return "サーバーエラー: \(code)"
        }
    }
}

// MARK: - EngagementFixtures

enum EngagementFixtures {
    static let likedState: (isLiked: Bool, likeCount: Int) = (true, 10)
    static let unlikedState: (isLiked: Bool, likeCount: Int) = (false, 9)
    static let bookmarkedState: (isBookmarked: Bool, bookmarkCount: Int) = (true, 5)
    static let unbookmarkedState: (isBookmarked: Bool, bookmarkCount: Int) = (false, 4)
}
