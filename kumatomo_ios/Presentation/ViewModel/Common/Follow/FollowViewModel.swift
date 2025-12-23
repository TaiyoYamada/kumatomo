import Foundation
import SwiftUI
import Factory

// MARK: - FollowViewModel

/// フォロー操作とフォロワー/フォロー中リスト管理のViewModel
@MainActor
@Observable
final class FollowViewModel {
    // MARK: - Published Properties

    var followers: [FollowUser] = []
    var following: [FollowUser] = []
    var isLoadingFollowers = false
    var isLoadingFollowing = false
    var isFollowActionInProgress = false
    var errorMessage: String?
    var successMessage: String?

    // Pagination
    private var followersPage = 1
    private var followingPage = 1
    private let pageSize = 20
    var hasMoreFollowers = true
    var hasMoreFollowing = true

    // MARK: - Dependencies

    @ObservationIgnored
    private let followUserUseCase: FollowUserUseCaseProtocol

    @ObservationIgnored
    private let unfollowUserUseCase: UnfollowUserUseCaseProtocol

    @ObservationIgnored
    private let fetchFollowersUseCase: FetchFollowersUseCaseProtocol

    @ObservationIgnored
    private let fetchFollowingUseCase: FetchFollowingUseCaseProtocol

    // MARK: - Initialization

    init(
        followUserUseCase: FollowUserUseCaseProtocol? = nil,
        unfollowUserUseCase: UnfollowUserUseCaseProtocol? = nil,
        fetchFollowersUseCase: FetchFollowersUseCaseProtocol? = nil,
        fetchFollowingUseCase: FetchFollowingUseCaseProtocol? = nil
    ) {
        self.followUserUseCase = followUserUseCase ?? Container.shared.followUserUseCase()
        self.unfollowUserUseCase = unfollowUserUseCase ?? Container.shared.unfollowUserUseCase()
        self.fetchFollowersUseCase = fetchFollowersUseCase ?? Container.shared.fetchFollowersUseCase()
        self.fetchFollowingUseCase = fetchFollowingUseCase ?? Container.shared.fetchFollowingUseCase()
    }

    // MARK: - Follow Actions

    /// ユーザーをフォロー
    func followUser(userId: Int) async -> Bool {
        guard !isFollowActionInProgress else { return false }
        isFollowActionInProgress = true
        errorMessage = nil

        do {
            try await followUserUseCase.execute(userId: userId)
            successMessage = "フォローしました"
            isFollowActionInProgress = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isFollowActionInProgress = false
            return false
        }
    }

    /// フォロー解除
    func unfollowUser(userId: Int) async -> Bool {
        guard !isFollowActionInProgress else { return true }
        isFollowActionInProgress = true
        errorMessage = nil

        do {
            try await unfollowUserUseCase.execute(userId: userId)
            successMessage = "フォロー解除しました"
            isFollowActionInProgress = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isFollowActionInProgress = false
            return true
        }
    }

    /// フォロー状態をトグル
    func toggleFollow(userId: Int, isCurrentlyFollowing: Bool) async -> Bool {
        if isCurrentlyFollowing {
            return await unfollowUser(userId: userId)
        } else {
            return await followUser(userId: userId)
        }
    }

    // MARK: - Fetch Followers

    /// フォロワー一覧取得（初回）
    func fetchFollowers(userId: Int) async {
        guard !isLoadingFollowers else { return }
        isLoadingFollowers = true
        errorMessage = nil
        followersPage = 1

        do {
            let users = try await fetchFollowersUseCase.execute(
                userId: userId,
                page: followersPage,
                limit: pageSize
            )
            followers = users
            hasMoreFollowers = users.count >= pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingFollowers = false
    }

    /// フォロワー追加読み込み
    func loadMoreFollowers(userId: Int) async {
        guard !isLoadingFollowers, hasMoreFollowers else { return }
        isLoadingFollowers = true
        followersPage += 1

        do {
            let users = try await fetchFollowersUseCase.execute(
                userId: userId,
                page: followersPage,
                limit: pageSize
            )
            followers.append(contentsOf: users)
            hasMoreFollowers = users.count >= pageSize
        } catch {
            followersPage -= 1
        }

        isLoadingFollowers = false
    }

    // MARK: - Fetch Following

    /// フォロー中ユーザー一覧取得（初回）
    func fetchFollowing(userId: Int) async {
        guard !isLoadingFollowing else { return }
        isLoadingFollowing = true
        errorMessage = nil
        followingPage = 1

        do {
            let users = try await fetchFollowingUseCase.execute(
                userId: userId,
                page: followingPage,
                limit: pageSize
            )
            following = users
            hasMoreFollowing = users.count >= pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingFollowing = false
    }

    /// フォロー中ユーザー追加読み込み
    func loadMoreFollowing(userId: Int) async {
        guard !isLoadingFollowing, hasMoreFollowing else { return }
        isLoadingFollowing = true
        followingPage += 1

        do {
            let users = try await fetchFollowingUseCase.execute(
                userId: userId,
                page: followingPage,
                limit: pageSize
            )
            following.append(contentsOf: users)
            hasMoreFollowing = users.count >= pageSize
        } catch {
            followingPage -= 1
        }

        isLoadingFollowing = false
    }

    // MARK: - Update Follow Status in Lists

    /// リスト内のユーザーのフォロー状態を更新
    func updateFollowStatus(userId: Int, isFollowing: Bool) {
        // Update in followers list
        if let index = followers.firstIndex(where: { $0.id == userId }) {
            followers[index].isFollowing = isFollowing
        }
        // Update in following list
        if let index = following.firstIndex(where: { $0.id == userId }) {
            following[index].isFollowing = isFollowing
        }
    }

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }

    /// 成功メッセージをクリア
    func clearSuccess() {
        successMessage = nil
    }
}
