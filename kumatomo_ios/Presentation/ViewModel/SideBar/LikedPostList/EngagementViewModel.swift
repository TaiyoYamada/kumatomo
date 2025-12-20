import Foundation
import SwiftUI
import Resolver
import Observation

// MARK: - EngagementViewModel

@MainActor
@Observable
class EngagementViewModel {

    var likedPosts: [Post] = []
    var bookmarkedPosts: [Post] = []

    var isLoadingLikedPosts: Bool = false
    var isLoadingBookmarkedPosts: Bool = false
    var isRefreshingLikedPosts: Bool = false
    var isRefreshingBookmarkedPosts: Bool = false

    var likingPostIds: Set<Int> = []
    var bookmarkingPostIds: Set<Int> = []

    var errorMessage: String?
    var showErrorAlert: Bool = false

    var successMessage: String = ""
    var showSuccessMessage: Bool = false

    var hasMoreLikedPosts: Bool = true
    var hasMoreBookmarkedPosts: Bool = true
    var likedPostsPage: Int = 1
    var bookmarkedPostsPage: Int = 1

    @ObservationIgnored @Injected var fetchLikedPostsUseCase: FetchLikedPostsUseCase
    @ObservationIgnored @Injected var fetchBookmarkedPostsUseCase: FetchBookmarkedPostsUseCase
    @ObservationIgnored @Injected var toggleLikeUseCase: ToggleLikeUseCase
    @ObservationIgnored @Injected var toggleBookmarkUseCase: ToggleBookmarkUseCase

    private let postsPerPage = 20

    var hasLikedPosts: Bool {
        return !likedPosts.isEmpty
    }

    var hasBookmarkedPosts: Bool {
        return !bookmarkedPosts.isEmpty
    }

    var isPerformingAnyAction: Bool {
        return isLoadingLikedPosts || isLoadingBookmarkedPosts ||
            isRefreshingLikedPosts || isRefreshingBookmarkedPosts ||
            !likingPostIds.isEmpty || !bookmarkingPostIds.isEmpty
    }

    init() {
        print("🎯 EngagementViewModel初期化")
    }

    func loadLikedPosts(refresh: Bool = false) async {
        guard !isLoadingLikedPosts, !isRefreshingLikedPosts else {
            print("⚠️ いいねした投稿の読み込み中 - スキップ")
            return
        }

        if refresh {
            isRefreshingLikedPosts = true
            likedPostsPage = 1
            hasMoreLikedPosts = true
        } else {
            isLoadingLikedPosts = true
        }

        clearError()

        print("[EngagementVM] loadLikedPosts start page=\(likedPostsPage) refresh=\(refresh))")

        do {
            let fetchedPosts = try await fetchLikedPostsUseCase.execute(page: likedPostsPage, limit: postsPerPage)

            if refresh {
                likedPosts = fetchedPosts
            } else {
                let newPosts = fetchedPosts.filter { newPost in
                    !likedPosts.contains { existingPost in
                        existingPost.id == newPost.id
                    }
                }
                likedPosts.append(contentsOf: newPosts)
            }

            hasMoreLikedPosts = fetchedPosts.count >= postsPerPage
            if !refresh, hasMoreLikedPosts {
                likedPostsPage += 1
            }

            print("[EngagementVM] loadLikedPosts success count=\(fetchedPosts.count) total=\(likedPosts.count)")

        } catch let error as EngagementError {
            if case .requestCancelled = error {
                print("ℹ️ いいねした投稿読み込み: リクエストキャンセルを無視")
            } else {
                await handleEngagementError(error, context: "いいねした投稿読み込み")
            }
        } catch {
            await handleGenericError(error, context: "いいねした投稿読み込み")
        }

        isLoadingLikedPosts = false
        isRefreshingLikedPosts = false
        print("[EngagementVM] loadLikedPosts end")
    }

    func refreshLikedPosts() async {
        await loadLikedPosts(refresh: true)
    }

    func loadMoreLikedPosts() async {
        guard hasMoreLikedPosts, !isLoadingLikedPosts else { return }
        await loadLikedPosts(refresh: false)
    }

    func loadBookmarkedPosts(refresh: Bool = false) async {
        guard !isLoadingBookmarkedPosts, !isRefreshingBookmarkedPosts else {
            print("⚠️ ブックマークした投稿の読み込み中 - スキップ")
            return
        }

        if refresh {
            isRefreshingBookmarkedPosts = true
            bookmarkedPostsPage = 1
            hasMoreBookmarkedPosts = true
        } else {
            isLoadingBookmarkedPosts = true
        }

        clearError()

        print("[EngagementVM] loadBookmarkedPosts start page=\(bookmarkedPostsPage) refresh=\(refresh))")

        do {
            let fetchedPosts = try await fetchBookmarkedPostsUseCase.execute(
                page: bookmarkedPostsPage,
                limit: postsPerPage
            )

            if refresh {
                bookmarkedPosts = fetchedPosts
            } else {
                let newPosts = fetchedPosts.filter { newPost in
                    !bookmarkedPosts.contains { existingPost in
                        existingPost.id == newPost.id
                    }
                }
                bookmarkedPosts.append(contentsOf: newPosts)
            }

            hasMoreBookmarkedPosts = fetchedPosts.count >= postsPerPage
            if !refresh, hasMoreBookmarkedPosts {
                bookmarkedPostsPage += 1
            }

            print(
                "[EngagementVM] loadBookmarkedPosts success count=\(fetchedPosts.count) total=\(bookmarkedPosts.count)"
            )

        } catch let error as EngagementError {
            if case .requestCancelled = error {
                print("ℹ️ ブックマークした投稿読み込み: リクエストキャンセルを無視")
            } else {
                await handleEngagementError(error, context: "ブックマークした投稿読み込み")
            }
        } catch {
            await handleGenericError(error, context: "ブックマークした投稿読み込み")
        }

        isLoadingBookmarkedPosts = false
        isRefreshingBookmarkedPosts = false
        print("[EngagementVM] loadBookmarkedPosts end")
    }

    func refreshBookmarkedPosts() async {
        await loadBookmarkedPosts(refresh: true)
    }

    func loadMoreBookmarkedPosts() async {
        guard hasMoreBookmarkedPosts, !isLoadingBookmarkedPosts else { return }
        await loadBookmarkedPosts(refresh: false)
    }

    func toggleLike(for post: Post) async {
        guard !likingPostIds.contains(post.id) else {
            print("⚠️ 投稿ID \(post.id) のいいね処理中 - スキップ")
            return
        }

        likingPostIds.insert(post.id)
        clearError()

        let originalIsLiked = post.isLikedByCurrentUser ?? false
        let originalLikeCount = post.likeCount ?? 0

        let newIsLiked = !originalIsLiked
        let newLikeCount = originalIsLiked ? max(0, originalLikeCount - 1) : originalLikeCount + 1

        updatePostInCollections(postId: post.id) { post in
            post.updateLikeStatus(isLiked: newIsLiked, likeCount: newLikeCount)
        }

        print("🔄 いいね最適化更新: 投稿ID \(post.id) - \(newIsLiked ? "いいね" : "いいね解除") (カウント: \(newLikeCount))")

        let result = await toggleLikeUseCase.execute(
            postId: post.id,
            currentState: originalIsLiked,
            currentCount: originalLikeCount
        )

        switch result {
        case let .success(response):
            updatePostInCollections(postId: post.id) { post in
                post.updateLikeStatus(isLiked: response.isLiked, likeCount: response.likeCount)
            }

            if !response.isLiked {
                likedPosts.removeAll { $0.id == post.id }
            }

            await showSuccess(response.isLiked ? "いいねしました" : "いいねを取り消しました")
            print(
                "✅ いいね更新成功: 投稿ID \(post.id) - \(response.isLiked ? "いいね" : "いいね解除") (サーバーカウント: \(response.likeCount))"
            )
        case let .failure(error):
            updatePostInCollections(postId: post.id) { post in
                post.updateLikeStatus(isLiked: originalIsLiked, likeCount: originalLikeCount)
            }

            await handleEngagementError(error, context: "いいね切り替え")
            print("❌ いいね更新失敗: 投稿ID \(post.id) - ロールバック実行")
        }

        likingPostIds.remove(post.id)
    }

    func toggleBookmark(for post: Post) async {
        guard !bookmarkingPostIds.contains(post.id) else {
            print("⚠️ 投稿ID \(post.id) のブックマーク処理中 - スキップ")
            return
        }

        bookmarkingPostIds.insert(post.id)
        clearError()

        let originalIsBookmarked = post.isBookmarkedByCurrentUser ?? false
        let originalBookmarkCount = post.bookmarkCount ?? 0

        let newIsBookmarked = !originalIsBookmarked
        let newBookmarkCount = originalIsBookmarked ? max(0, originalBookmarkCount - 1) : originalBookmarkCount + 1

        updatePostInCollections(postId: post.id) { post in
            post.updateBookmarkStatus(isBookmarked: newIsBookmarked, bookmarkCount: newBookmarkCount)
        }

        print("🔄 ブックマーク最適化更新: 投稿ID \(post.id) - \(newIsBookmarked ? "ブックマーク" : "ブックマーク解除") (カウント: \(newBookmarkCount))")

        let result = await toggleBookmarkUseCase.execute(
            postId: post.id,
            currentState: originalIsBookmarked,
            currentCount: originalBookmarkCount
        )

        switch result {
        case let .success(response):
            updatePostInCollections(postId: post.id) { post in
                post.updateBookmarkStatus(isBookmarked: response.isBookmarked, bookmarkCount: response.bookmarkCount)
            }

            if !response.isBookmarked {
                bookmarkedPosts.removeAll { $0.id == post.id }
            }

            await showSuccess(response.isBookmarked ? "ブックマークしました" : "ブックマークを取り消しました")
            print(
                "✅ ブックマーク更新成功: 投稿ID \(post.id) - \(response.isBookmarked ? "ブックマーク" : "ブックマーク解除") (サーバーカウント: \(response.bookmarkCount))"
            )
        case let .failure(error):
            updatePostInCollections(postId: post.id) { post in
                post.updateBookmarkStatus(isBookmarked: originalIsBookmarked, bookmarkCount: originalBookmarkCount)
            }

            await handleEngagementError(error, context: "ブックマーク切り替え")
            print("❌ ブックマーク更新失敗: 投稿ID \(post.id) - ロールバック実行")
        }

        bookmarkingPostIds.remove(post.id)
    }

    private func updatePostInCollections(postId: Int, updateBlock: (inout Post) -> Void) {
        if let index = likedPosts.firstIndex(where: { $0.id == postId }) {
            updateBlock(&likedPosts[index])
        }

        if let index = bookmarkedPosts.firstIndex(where: { $0.id == postId }) {
            updateBlock(&bookmarkedPosts[index])
        }
    }

    func isLiking(postId: Int) -> Bool {
        return likingPostIds.contains(postId)
    }

    func isBookmarking(postId: Int) -> Bool {
        return bookmarkingPostIds.contains(postId)
    }

    func getPost(byId postId: Int) -> Post? {
        return likedPosts.first { $0.id == postId } ??
            bookmarkedPosts.first { $0.id == postId }
    }

    func removePost(withId postId: Int) {
        likedPosts.removeAll { $0.id == postId }
        bookmarkedPosts.removeAll { $0.id == postId }
        print("🗑️ 投稿ID \(postId) をコレクションから削除")
    }

    func reset() {
        likedPosts = []
        bookmarkedPosts = []
        isLoadingLikedPosts = false
        isLoadingBookmarkedPosts = false
        isRefreshingLikedPosts = false
        isRefreshingBookmarkedPosts = false
        likingPostIds = []
        bookmarkingPostIds = []
        hasMoreLikedPosts = true
        hasMoreBookmarkedPosts = true
        likedPostsPage = 1
        bookmarkedPostsPage = 1
        clearError()
        clearSuccess()
        print("🔄 EngagementViewModel状態リセット")
    }

    private func clearError() {
        errorMessage = nil
        showErrorAlert = false
    }

    private func clearSuccess() {
        successMessage = ""
        showSuccessMessage = false
    }

    private func showSuccess(_ message: String) async {
        successMessage = message
        showSuccessMessage = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showSuccessMessage = false
        }
    }

    private func handleEngagementError(_ error: EngagementError, context: String) async {
        let message = "\(context)エラー: \(error.localizedDescription)"
        errorMessage = message
        showErrorAlert = true
        print("🚨 [\(context)] EngagementError: \(error.localizedDescription)")
    }

    private func handleGenericError(_ error: Error, context: String) async {
        let message = "\(context)エラー: \(error.localizedDescription)"
        errorMessage = message
        showErrorAlert = true
        print("🚨 [\(context)] GenericError: \(error.localizedDescription)")
    }
}

extension EngagementViewModel {
    var formattedCounts: (likedPosts: String, bookmarkedPosts: String) {
        let likedCount = formatCount(likedPosts.count)
        let bookmarkedCount = formatCount(bookmarkedPosts.count)

        return (likedPosts: likedCount, bookmarkedPosts: bookmarkedCount)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }

    var engagementSummary: String {
        var parts: [String] = []

        if !likedPosts.isEmpty {
            parts.append("\(likedPosts.count)件のいいね")
        }

        if !bookmarkedPosts.isEmpty {
            parts.append("\(bookmarkedPosts.count)件のブックマーク")
        }

        if parts.isEmpty {
            return "エンゲージメントなし"
        }

        return parts.joined(separator: " • ")
    }

    var hasNoEngagement: Bool {
        return likedPosts.isEmpty && bookmarkedPosts.isEmpty
    }

    var totalEngagementCount: Int {
        return likedPosts.count + bookmarkedPosts.count
    }
}
