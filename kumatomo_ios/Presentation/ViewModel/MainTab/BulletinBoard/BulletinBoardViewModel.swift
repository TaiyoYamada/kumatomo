import Foundation
import SwiftUI
import Combine
import Observation
import Factory

// MARK: - BulletinBoardViewModel

@MainActor
@Observable
class BulletinBoardViewModel {

    var posts: [Post] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var isRefreshing: Bool = false

    var activeTab: TabType = .all
    var selectedMunicipality: String?

    var hasMorePosts: Bool = true
    var isLoadingMore: Bool = false

    var reactionUpdates: [Int: PostReactions] = [:]
    var userReactions: [Int: ReactionType] = [:]
    var bookmarkedPosts: Set<Int> = []

    @ObservationIgnored @Injected(\.fetchAllPostsWithCacheUseCase) var fetchAllPostsWithCacheUseCase
    @ObservationIgnored @Injected(\.fetchMunicipalityPostsWithCacheUseCase) var fetchMunicipalityPostsWithCacheUseCase
    @ObservationIgnored @Injected(\.fetchFollowingPostsWithCacheUseCase) var fetchFollowingPostsWithCacheUseCase
    @ObservationIgnored @Injected(\.toggleLikeUseCase) var toggleLikeUseCase
    @ObservationIgnored @Injected(\.toggleBookmarkUseCase) var toggleBookmarkUseCase
    @ObservationIgnored @Injected(\.toggleReactionUseCase) var toggleReactionUseCase
    private var currentPage = 1
    private let postsPerPage = 20
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
        loadUserPreferences()
    }

    func loadInitialPosts() {
        Task {
            await fetchPostsForCurrentTab()
        }
    }

    func refreshPosts() {
        Task {
            await refreshPostsForCurrentTab()
        }
    }

    func loadMorePosts() {
        guard !isLoadingMore, hasMorePosts else { return }

        Task {
            await fetchMorePostsForCurrentTab()
        }
    }

    func changeTab(_ tab: TabType) {
        guard activeTab != tab else { return }

        activeTab = tab
        resetPagination()

        Task {
            await fetchPostsForCurrentTab()
        }
    }

    func changeMunicipality(_ municipality: String) {
        selectedMunicipality = municipality
        saveUserPreferences()

        if activeTab == .municipality {
            resetPagination()
            Task {
                await fetchPostsForCurrentTab()
            }
        }
    }

    func toggleLike(for post: Post) {
        Task {
            await handleLikeToggle(for: post)
        }
    }

    func toggleBookmark(for post: Post) {
        Task {
            await handleBookmarkToggle(for: post)
        }
    }

    func navigateToComments(for post: Post) {
        print("Navigate to comments for post \(post.id)")
    }

    func toggleReaction(_ reactionType: ReactionType, for post: Post) {
        Task {
            await handleReactionToggle(reactionType, for: post)
        }
    }

    func clearCache() {
        PostCacheManager.shared.clearAllCache()
        print("📦 キャッシュをクリアしました")
    }

    func getCacheInfo() -> (totalSize: Int, itemCount: Int, lastUpdated: Date?) {
        return PostCacheManager.shared.getCacheInfo()
    }

    func isOfflineMode() -> Bool {
        return !NetworkMonitor.shared.isConnected
    }

    func getNetworkStatus() -> String {
        return NetworkMonitor.shared.getNetworkStatusMessage()
    }

    private func setupBindings() {
        NotificationCenter.default.publisher(for: .NetworkConnectivityChanged)
            .sink { [weak self] note in
                guard let self else { return }
                if let isConnected = note.userInfo?["isConnected"] as? Bool, isConnected {
                    Task { @MainActor in
                        self.handleNetworkConnectivityChange()
                    }
                }
                if let connectionType = note.userInfo?["connectionType"] as? NetworkMonitor.ConnectionType {
                    Task { @MainActor in
                        self.handleConnectionTypeChange(connectionType)
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func resetPagination() {
        currentPage = 1
        hasMorePosts = true
        posts.removeAll()
    }

    private func fetchPostsForCurrentTab() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedPosts = try await fetchPostsBasedOnTab()

            posts = fetchedPosts
            currentPage = 1
            hasMorePosts = fetchedPosts.count >= postsPerPage

        } catch {
            await handleError(error, context: "投稿の取得")
        }

        isLoading = false
    }

    private func refreshPostsForCurrentTab() async {
        isRefreshing = true
        errorMessage = nil

        do {
            let fetchedPosts = try await fetchPostsBasedOnTab()

            posts = fetchedPosts
            currentPage = 1
            hasMorePosts = fetchedPosts.count >= postsPerPage

        } catch {
            await handleError(error, context: "投稿の更新")
        }

        isRefreshing = false
    }

    private func fetchMorePostsForCurrentTab() async {
        isLoadingMore = true

        do {
            let nextPage = currentPage + 1
            let fetchedPosts = try await fetchPostsBasedOnTab(page: nextPage)

            if !fetchedPosts.isEmpty {
                posts.append(contentsOf: fetchedPosts)
                currentPage = nextPage
                hasMorePosts = fetchedPosts.count >= postsPerPage
            } else {
                hasMorePosts = false
            }

        } catch {
            await handleError(error, context: "追加投稿の取得")
        }

        isLoadingMore = false
    }

    private func fetchPostsBasedOnTab(page: Int = 1) async throws -> [Post] {
        let isConnected = NetworkMonitor.shared.isConnected
        let shouldLimitData = NetworkMonitor.shared.shouldLimitDataUsage()
        let useCache = !isConnected || shouldLimitData

        switch activeTab {
        case .all:
            return try await fetchAllPostsWithCacheUseCase.execute(
                page: page,
                limit: postsPerPage,
                useCache: useCache
            )
        case .municipality:
            guard let municipality = selectedMunicipality else {
                throw BulletinBoardError.municipalityNotSelected
            }
            return try await fetchMunicipalityPostsWithCacheUseCase.execute(
                municipality: municipality,
                page: page,
                limit: postsPerPage,
                useCache: useCache
            )
        case .following:
            return try await fetchFollowingPostsWithCacheUseCase.execute(
                page: page,
                limit: postsPerPage,
                useCache: useCache
            )
        }
    }

    private func handleLikeToggle(for post: Post) async {
        let postId = post.id

        let originalIsLiked = post.isLikedByCurrentUser ?? false
        let originalLikeCount = post.likeCount ?? 0

        let newIsLiked = !originalIsLiked
        let newLikeCount = originalIsLiked ? max(0, originalLikeCount - 1) : originalLikeCount + 1

        updatePostInList(postId: postId) { post in
            post.updateLikeStatus(isLiked: newIsLiked, likeCount: newLikeCount)
        }

        print("🔄 いいね最適化更新: \(newIsLiked ? "いいね" : "いいね解除") (カウント: \(newLikeCount))")

        do {
            if NetworkMonitor.shared.isConnected {
                let likeResult = await toggleLikeUseCase.execute(
                    postId: postId,
                    currentState: originalIsLiked,
                    currentCount: originalLikeCount
                )
                guard case let .success(response) = likeResult else { throw EngagementError.unknownError(NSError(
                    domain: "toggleLike",
                    code: -1
                )) }

                updatePostInList(postId: postId) { post in
                    post.updateLikeStatus(isLiked: response.isLiked, likeCount: response.likeCount)
                }

                print("✅ いいね更新成功: \(response.isLiked ? "いいね" : "いいね解除") (サーバーカウント: \(response.likeCount))")
            } else {
                print("📱 オフライン: いいねをローカルに保存")
            }

        } catch {
            updatePostInList(postId: postId) { post in
                post.updateLikeStatus(isLiked: originalIsLiked, likeCount: originalLikeCount)
            }

            await handleError(error, context: "いいね切り替え")
            print("❌ いいね更新失敗 - ロールバック実行")
        }
    }

    private func handleReactionToggle(_ reactionType: ReactionType, for post: Post) async {
        let postId = post.id
        let currentUserReaction = userReactions[postId]

        var updatedReactions = post.reactions ?? PostReactions()

        if currentUserReaction == reactionType {
            updatedReactions.decrement(reactionType)
            userReactions.removeValue(forKey: postId)
        } else {
            if let oldReaction = currentUserReaction {
                updatedReactions.decrement(oldReaction)
            }
            updatedReactions.increment(reactionType)
            userReactions[postId] = reactionType
        }

        reactionUpdates[postId] = updatedReactions
        updatePostInList(postId: postId) { post in
            post.reactions = updatedReactions
            post.userReaction = userReactions[postId]
        }

        PostCacheManager.shared.cacheReactions(reactionUpdates)

        do {
            if NetworkMonitor.shared.isConnected {
                let serverReactions = try await toggleReactionUseCase.execute(
                    postId: postId,
                    reactionType: reactionType
                )

                reactionUpdates[postId] = serverReactions.reactions
                userReactions[postId] = serverReactions.userReaction

                updatePostInList(postId: postId) { post in
                    post.reactions = serverReactions.reactions
                    post.userReaction = serverReactions.userReaction
                }

                PostCacheManager.shared.cacheReactions(reactionUpdates)
            } else {
                print("📱 オフライン: リアクションをローカルに保存")
            }

        } catch {
            reactionUpdates.removeValue(forKey: postId)
            userReactions[postId] = currentUserReaction

            updatePostInList(postId: postId) { post in
                post.reactions = post.reactions
                post.userReaction = currentUserReaction
            }

            PostCacheManager.shared.cacheReactions(reactionUpdates)

            await handleError(error, context: "リアクションの更新")
        }
    }

    private func handleBookmarkToggle(for post: Post) async {
        let postId = post.id

        let originalIsBookmarked = post.isBookmarkedByCurrentUser ?? false
        let originalBookmarkCount = post.bookmarkCount ?? 0

        let newIsBookmarked = !originalIsBookmarked
        let newBookmarkCount = originalIsBookmarked ? max(0, originalBookmarkCount - 1) : originalBookmarkCount + 1

        updatePostInList(postId: postId) { post in
            post.updateBookmarkStatus(isBookmarked: newIsBookmarked, bookmarkCount: newBookmarkCount)
        }

        if newIsBookmarked {
            bookmarkedPosts.insert(postId)
        } else {
            bookmarkedPosts.remove(postId)
        }

        PostCacheManager.shared.cacheBookmarks(bookmarkedPosts)

        print("🔄 ブックマーク最適化更新: \(newIsBookmarked ? "ブックマーク" : "ブックマーク解除") (カウント: \(newBookmarkCount))")

        do {
            if NetworkMonitor.shared.isConnected {
                let bookmarkResult = await toggleBookmarkUseCase.execute(
                    postId: postId,
                    currentState: originalIsBookmarked,
                    currentCount: originalBookmarkCount
                )
                guard case let .success(response) = bookmarkResult else { throw EngagementError.unknownError(NSError(
                    domain: "toggleBookmark",
                    code: -1
                )) }

                updatePostInList(postId: postId) { post in
                    post.updateBookmarkStatus(
                        isBookmarked: response.isBookmarked,
                        bookmarkCount: response.bookmarkCount
                    )
                }

                if response.isBookmarked {
                    bookmarkedPosts.insert(postId)
                } else {
                    bookmarkedPosts.remove(postId)
                }

                PostCacheManager.shared.cacheBookmarks(bookmarkedPosts)

                print(
                    "✅ ブックマーク更新成功: \(response.isBookmarked ? "ブックマーク" : "ブックマーク解除") (サーバーカウント: \(response.bookmarkCount))"
                )
            } else {
                print("📱 オフライン: ブックマークをローカルに保存")
            }

        } catch {
            updatePostInList(postId: postId) { post in
                post.updateBookmarkStatus(isBookmarked: originalIsBookmarked, bookmarkCount: originalBookmarkCount)
            }

            if originalIsBookmarked {
                bookmarkedPosts.insert(postId)
            } else {
                bookmarkedPosts.remove(postId)
            }

            PostCacheManager.shared.cacheBookmarks(bookmarkedPosts)

            await handleError(error, context: "ブックマークの更新")
            print("❌ ブックマーク更新失敗 - ロールバック実行")
        }
    }

    private func updatePostInList(postId: Int, update: (inout Post) -> Void) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            update(&posts[index])
        }
    }

    private func handleNetworkConnectivityChange() {
        if NetworkMonitor.shared.isConnected {
            errorMessage = nil
            Task {
                await refreshPostsForCurrentTab()
            }
        }
    }

    private func handleConnectionTypeChange(_ connectionType: NetworkMonitor.ConnectionType) {
        if NetworkMonitor.shared.shouldLimitDataUsage() {
            print("📱 データ使用量制限モードに切り替え")
        } else {
            print("📱 通常モードに切り替え")
        }
    }

    private func loadUserPreferences() {
        selectedMunicipality = UserDefaults.standard.string(forKey: "selectedMunicipality")

        reactionUpdates = PostCacheManager.shared.getCachedReactions()
        bookmarkedPosts = PostCacheManager.shared.getCachedBookmarks()

        print("📦 ユーザー設定を読み込み: 市町村=\(selectedMunicipality ?? "未選択"), ブックマーク=\(bookmarkedPosts.count)件")
    }

    private func saveUserPreferences() {
        UserDefaults.standard.set(selectedMunicipality, forKey: "selectedMunicipality")

        PostCacheManager.shared.cacheReactions(reactionUpdates)
        PostCacheManager.shared.cacheBookmarks(bookmarkedPosts)

        print("📦 ユーザー設定を保存: 市町村=\(selectedMunicipality ?? "未選択"), ブックマーク=\(bookmarkedPosts.count)件")
    }

    private func handleError(_ error: Error, context: String) async {
        let errorMessage: String
        let isNetworkError = NetworkMonitor.shared.isNetworkError(error)

        if let bulletinBoardError = error as? BulletinBoardError {
            errorMessage = bulletinBoardError.localizedDescription
        } else if let postAPIError = error as? PostAPIError {
            errorMessage = postAPIError.localizedDescription
        } else if isNetworkError {
            errorMessage = NetworkMonitor.shared.getNetworkErrorMessage(error)
        } else {
            errorMessage = "\(context)中にエラーが発生しました: \(error.localizedDescription)"
        }

        if !NetworkMonitor.shared.isConnected {
            self.errorMessage = "オフライン: \(errorMessage)"
        } else if NetworkMonitor.shared.shouldLimitDataUsage() {
            self.errorMessage = "制限モード: \(errorMessage)"
        } else {
            self.errorMessage = errorMessage
        }

        print("🚨 \(context)エラー: \(self.errorMessage ?? errorMessage)")

        if isNetworkError, NetworkMonitor.shared.shouldRetryNetworkRequest(error) {
            let retryDelay = NetworkMonitor.shared.getRetryDelay(for: error, attempt: 1)
            print("🔄 \(retryDelay)秒後に自動リトライします")

            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                Task { @MainActor in
                    await self?.refreshPostsForCurrentTab()
                }
            }
        }
    }
}
