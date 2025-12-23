import Combine
import Foundation
import UIKit

// MARK: - UsernameAvailabilityResponse

struct UsernameAvailabilityResponse: Codable {
    let available: Bool
    let message: String?
}

// MARK: - UserAPIService

final class UserAPIService {
    private let client: APIClient

    // internal init for dependency injection
    init(client: APIClient) {
        self.client = client
    }

    // MARK: - Profile Fetching

    /// ユーザープロフィールを取得
    func fetchProfile(userID: String) -> AnyPublisher<User, Error> {
        Future<User, Error> { promise in
            Task {
                do {
                    let user: UserResponse = try await self.client.get(UserEndpoint.fetchUser(userId: Int(userID) ?? 0))
                    promise(.success(user.data))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// ユーザープロフィールを取得（async版）
    func fetchProfileAsync(userId: Int) async throws -> User {
        let response: UserResponse = try await client.get(UserEndpoint.fetchUser(userId: userId))
        return response.data
    }

    /// ユーザープロフィールを取得（async版、String ID）
    func fetchProfileAsync(userID: String) async throws -> User {
        guard let userId = Int(userID) else {
            throw APIError.invalidURL
        }
        return try await fetchProfileAsync(userId: userId)
    }

    // MARK: - Profile Creation

    /// プロフィールを作成
    func createProfile(_ user: User) -> AnyPublisher<User, Error> {
        Future<User, Error> { promise in
            Task {
                do {
                    let data: [String: Any] = [
                        "name": user.name ?? "",
                        "email": user.email ?? "",
                        "bio": user.bio ?? "",
                        "location": user.location ?? ""
                    ]
                    let response: UserResponse = try await self.client.post(UserEndpoint.updateProfile(data: data))
                    promise(.success(response.data))
                } catch {
                    promise(.failure(ProfileError.profileCreationFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// プロフィールを作成（async版）
    func createProfile(_ user: User) async throws -> User {
        let data: [String: Any] = [
            "name": user.name ?? "",
            "email": user.email ?? "",
            "bio": user.bio ?? "",
            "location": user.location ?? ""
        ]
        let response: UserResponse = try await client.post(UserEndpoint.updateProfile(data: data))
        return response.data
    }

    // MARK: - Profile Updates

    /// プロフィールを更新
    func updateProfile(_ user: User) -> AnyPublisher<User, Error> {
        Future<User, Error> { promise in
            Task {
                do {
                    var data: [String: Any] = [
                        "name": user.name ?? "",
                        "bio": user.bio ?? "",
                        "location": user.location ?? ""
                    ]
                    // 画像URLも含める
                    if let profileImageURL = user.profileImageURL {
                        data["profileImageURL"] = profileImageURL
                    }
                    if let coverImageURL = user.coverImageURL {
                        data["coverImageURL"] = coverImageURL
                    }
                    let response: UserResponse = try await self.client.put(UserEndpoint.updateProfile(data: data))
                    promise(.success(response.data))
                } catch {
                    promise(.failure(ProfileError.profileUpdateFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// プロフィールを更新（async版）
    func updateProfile(_ user: User) async throws -> User {
        var data: [String: Any] = [
            "name": user.name ?? "",
            "bio": user.bio ?? "",
            "location": user.location ?? ""
        ]
        // 画像URLも含める
        if let profileImageURL = user.profileImageURL {
            data["profileImageURL"] = profileImageURL
        }
        if let coverImageURL = user.coverImageURL {
            data["coverImageURL"] = coverImageURL
        }
        let response: UserResponse = try await client.put(UserEndpoint.updateProfile(data: data))
        return response.data
    }

    /// プロフィールを更新（async版、データ辞書）
    func updateProfileAsync(data: [String: Any]) async throws -> User {
        let response: UserResponse = try await client.put(UserEndpoint.updateProfile(data: data))
        return response.data
    }

    // MARK: - Profile Deletion

    /// プロフィールを削除
    func deleteProfile(userID: String) async throws {
        try await client.delete(UserEndpoint.fetchUser(userId: Int(userID) ?? 0))
    }

    // MARK: - Username

    /// ユーザーネームの利用可能性を確認
    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { promise in
            Task {
                do {
                    let response: UsernameAvailabilityResponse = try await self.client.request(
                        UsernameEndpoint.check(username: username)
                    )
                    promise(.success(response.available))
                } catch {
                    promise(.failure(ProfileError.usernameCheckFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// ユーザーネームを更新
    func updateUsername(_ username: String) -> AnyPublisher<User, Error> {
        Future<User, Error> { promise in
            Task {
                do {
                    let response: UserResponse = try await self.client.request(
                        UsernameEndpoint.update(username: username)
                    )
                    promise(.success(response.data))
                } catch {
                    promise(.failure(ProfileError.profileUpdateFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Follow Operations

    /// ユーザーをフォロー
    func followUser(userId: Int) async throws {
        try await client.requestVoid(UserEndpoint.follow(userId: userId))
    }

    /// ユーザーのフォローを解除
    func unfollowUser(userId: Int) async throws {
        try await client.requestVoid(UserEndpoint.unfollow(userId: userId))
    }

    /// フォロワー一覧を取得
    func fetchFollowers(userId: Int, page: Int? = nil, limit: Int? = nil) async throws -> [FollowUser] {
        try await client.get(UserEndpoint.fetchFollowers(userId: userId, page: page, limit: limit))
    }

    /// フォロー中一覧を取得
    func fetchFollowing(userId: Int, page: Int? = nil, limit: Int? = nil) async throws -> [FollowUser] {
        try await client.get(UserEndpoint.fetchFollowing(userId: userId, page: page, limit: limit))
    }

    /// フォロー状態を取得
    func fetchFollowStatus(userId: Int) async throws -> FollowStatusResponse {
        try await client.get(UserEndpoint.followStatus(userId: userId))
    }

    // MARK: - Profile Save (Combine)

    /// プロフィールを保存（updateProfileと同じ機能、後方互換性のため）
    func saveProfile(_ user: User) -> AnyPublisher<User, Error> {
        updateProfile(user)
    }

    // MARK: - Profile Deletion (Combine)

    /// プロフィールを削除（Combine版）
    func deleteProfile(userID: String) -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { promise in
            Task {
                do {
                    try await self.client.delete(UserEndpoint.fetchUser(userId: Int(userID) ?? 0))
                    promise(.success(true))
                } catch {
                    promise(.failure(ProfileError.profileDeletionFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Image Upload

    /// プロフィール画像をアップロード
    func uploadProfileImage(_ image: UIImage) -> AnyPublisher<String, Error> {
        Future<String, Error> { promise in
            Task {
                do {
                    let url = try await ImageUploadService.shared.uploadProfileImage(image)
                    promise(.success(url))
                } catch {
                    promise(.failure(ProfileError.imageUploadFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// カバー画像をアップロード
    func uploadCoverImage(_ image: UIImage) -> AnyPublisher<String, Error> {
        Future<String, Error> { promise in
            Task {
                do {
                    let url = try await ImageUploadService.shared.uploadCoverImage(image)
                    promise(.success(url))
                } catch {
                    promise(.failure(ProfileError.imageUploadFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

// MARK: - UsernameEndpoint

private enum UsernameEndpoint: APIEndpoint {
    case check(username: String)
    case update(username: String)

    var path: String {
        switch self {
        case .check: return "/users/check-username"
        case .update: return "/users/update-username"
        }
    }

    var method: HTTPMethod {
        return .post
    }

    var body: [String: Any]? {
        switch self {
        case let .check(username): return ["username": username]
        case let .update(username): return ["username": username]
        }
    }
}
