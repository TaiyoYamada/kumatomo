import Foundation

// MARK: - FetchFollowersUseCaseProtocol

/// フォロワー一覧取得ユースケースプロトコル
protocol FetchFollowersUseCaseProtocol: Sendable {
    func execute(userId: Int, page: Int, limit: Int) async throws -> [FollowUser]
}

// MARK: - FollowUser

/// フォロー関係のユーザー情報
struct FollowUser: Identifiable, Sendable, Codable {
    let id: Int
    let name: String?
    let username: String?
    let profileImageURL: String?
    let bio: String?
    var isFollowing: Bool?
    var isMe: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case username
        case profileImageURL = "profile_image_url"
        case bio
        case isFollowing = "is_following"
        case isMe = "is_me"
    }
}

// MARK: - FetchFollowersUseCase

/// フォロワー一覧取得ユースケース
struct FetchFollowersUseCase: FetchFollowersUseCaseProtocol {
    private let repository: FollowRepositoryProtocol

    init(repository: FollowRepositoryProtocol) {
        self.repository = repository
    }

    func execute(userId: Int, page: Int = 1, limit: Int = 20) async throws -> [FollowUser] {
        try await repository.fetchFollowers(userId: userId, page: page, limit: limit)
    }
}
