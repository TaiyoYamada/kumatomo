import Foundation
import SwiftUI
import Combine

@MainActor
class BulletinBoardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isRefreshing: Bool = false
    
    // Tab Management
    @Published var activeTab: TabType = .all
    @Published var selectedMunicipality: String?
    
    // Pagination
    @Published var hasMorePosts: Bool = true
    @Published var isLoadingMore: Bool = false
    
    // Reaction Management
    @Published var reactionUpdates: [Int: PostReactions] = [:]
    @Published var userReactions: [Int: ReactionType] = [:]
    @Published var bookmarkedPosts: Set<Int> = []
    
    // MARK: - Private Properties
    
    private let postAPIService = PostAPIService.shared
    private var currentPage = 1
    private let postsPerPage = 20
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        loadUserPreferences()
    }
    
    // MARK: - Public Methods
    
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
        guard !isLoadingMore && hasMorePosts else { return }
        
        Task {
            await fetchMorePostsForCurrentTab()
        }
    }
    
    // MARK: - Tab Management
    
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
    
    // MARK: - Reaction Management
    
    func toggleReaction(_ reactionType: ReactionType, for post: Post) {
        Task {
            await handleReactionToggle(reactionType, for: post)
        }
    }
    
    func toggleBookmark(for post: Post) {
        Task {
            await handleBookmarkToggle(for: post)
        }
    }
    
    func navigateToComments(for post: Post) {
        // TODO: Implement navigation to comment view
        print("Navigate to comments for post \(post.id)")
    }
    
    // MARK: - Cache Management
    
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
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor network connectivity changes
        NetworkMonitor.shared.$isConnected
            .dropFirst() // Skip initial value
            .sink { [weak self] isConnected in
                if isConnected {
                    Task { @MainActor in
                        self?.handleNetworkConnectivityChange()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Monitor connection type changes for data usage optimization
        NetworkMonitor.shared.$connectionType
            .dropFirst()
            .sink { [weak self] connectionType in
                Task { @MainActor in
                    self?.handleConnectionTypeChange(connectionType)
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
            return try await postAPIService.fetchAllPostsWithCache(
                page: page, 
                limit: postsPerPage, 
                useCache: useCache
            )
        case .municipality:
            guard let municipality = selectedMunicipality else {
                throw BulletinBoardError.municipalityNotSelected
            }
            return try await postAPIService.fetchMunicipalityPostsWithCache(
                municipality: municipality,
                page: page,
                limit: postsPerPage,
                useCache: useCache
            )
        case .following:
            return try await postAPIService.fetchFollowingPostsWithCache(
                page: page, 
                limit: postsPerPage, 
                useCache: useCache
            )
        }
    }
    
    private func handleReactionToggle(_ reactionType: ReactionType, for post: Post) async {
        let postId = post.id
        let currentUserReaction = userReactions[postId]
        
        // Optimistic update
        var updatedReactions = post.reactions ?? PostReactions()
        
        if currentUserReaction == reactionType {
            // Remove reaction
            updatedReactions.decrement(reactionType)
            userReactions.removeValue(forKey: postId)
        } else {
            // Add new reaction (remove old one if exists)
            if let oldReaction = currentUserReaction {
                updatedReactions.decrement(oldReaction)
            }
            updatedReactions.increment(reactionType)
            userReactions[postId] = reactionType
        }
        
        // Update local state
        reactionUpdates[postId] = updatedReactions
        updatePostInList(postId: postId) { post in
            post.reactions = updatedReactions
            post.userReaction = userReactions[postId]
        }
        
        // Save to cache immediately for offline support
        PostCacheManager.shared.cacheReactions(reactionUpdates)
        
        do {
            // Send to server if online
            if NetworkMonitor.shared.isConnected {
                let serverReactions = try await postAPIService.toggleReaction(
                    postId: postId,
                    reactionType: reactionType
                )
                
                // Update with server response
                reactionUpdates[postId] = serverReactions.reactions
                userReactions[postId] = serverReactions.userReaction
                
                updatePostInList(postId: postId) { post in
                    post.reactions = serverReactions.reactions
                    post.userReaction = serverReactions.userReaction
                }
                
                // Update cache with server data
                PostCacheManager.shared.cacheReactions(reactionUpdates)
            } else {
                print("📱 オフライン: リアクションをローカルに保存")
                // TODO: Queue for sync when online
            }
            
        } catch {
            // Rollback optimistic update
            reactionUpdates.removeValue(forKey: postId)
            userReactions[postId] = currentUserReaction
            
            updatePostInList(postId: postId) { post in
                post.reactions = post.reactions
                post.userReaction = currentUserReaction
            }
            
            // Restore cache
            PostCacheManager.shared.cacheReactions(reactionUpdates)
            
            await handleError(error, context: "リアクションの更新")
        }
    }
    
    private func handleBookmarkToggle(for post: Post) async {
        let postId = post.id
        let wasBookmarked = bookmarkedPosts.contains(postId)
        
        // Optimistic update
        if wasBookmarked {
            bookmarkedPosts.remove(postId)
        } else {
            bookmarkedPosts.insert(postId)
        }
        
        updatePostInList(postId: postId) { post in
            post.isBookmarked = !wasBookmarked
        }
        
        // Save to cache immediately for offline support
        PostCacheManager.shared.cacheBookmarks(bookmarkedPosts)
        
        do {
            // Send to server if online
            if NetworkMonitor.shared.isConnected {
                let isBookmarked = try await postAPIService.toggleBookmark(postId: postId)
                
                // Update with server response
                if isBookmarked {
                    bookmarkedPosts.insert(postId)
                } else {
                    bookmarkedPosts.remove(postId)
                }
                
                updatePostInList(postId: postId) { post in
                    post.isBookmarked = isBookmarked
                }
                
                // Update cache with server data
                PostCacheManager.shared.cacheBookmarks(bookmarkedPosts)
            } else {
                print("📱 オフライン: ブックマークをローカルに保存")
                // TODO: Queue for sync when online
            }
            
        } catch {
            // Rollback optimistic update
            if wasBookmarked {
                bookmarkedPosts.insert(postId)
            } else {
                bookmarkedPosts.remove(postId)
            }
            
            updatePostInList(postId: postId) { post in
                post.isBookmarked = wasBookmarked
            }
            
            // Restore cache
            PostCacheManager.shared.cacheBookmarks(bookmarkedPosts)
            
            await handleError(error, context: "ブックマークの更新")
        }
    }
    
    private func updatePostInList(postId: Int, update: (inout Post) -> Void) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            update(&posts[index])
        }
    }
    
    private func handleNetworkConnectivityChange() {
        // Refresh posts when network connectivity is restored
        if NetworkMonitor.shared.isConnected {
            errorMessage = nil // Clear offline error message
            Task {
                await refreshPostsForCurrentTab()
            }
        }
    }
    
    private func handleConnectionTypeChange(_ connectionType: NetworkMonitor.ConnectionType) {
        // Adjust behavior based on connection type
        if NetworkMonitor.shared.shouldLimitDataUsage() {
            print("📱 データ使用量制限モードに切り替え")
            // Could implement lower quality images, reduced refresh rate, etc.
        } else {
            print("📱 通常モードに切り替え")
        }
    }
    
    private func loadUserPreferences() {
        // Load saved municipality preference
        selectedMunicipality = UserDefaults.standard.string(forKey: "selectedMunicipality")
        
        // Load cached data
        reactionUpdates = PostCacheManager.shared.getCachedReactions()
        bookmarkedPosts = PostCacheManager.shared.getCachedBookmarks()
        
        print("📦 ユーザー設定を読み込み: 市町村=\(selectedMunicipality ?? "未選択"), ブックマーク=\(bookmarkedPosts.count)件")
    }
    
    private func saveUserPreferences() {
        // Save municipality preference
        UserDefaults.standard.set(selectedMunicipality, forKey: "selectedMunicipality")
        
        // Save cached data
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
        
        // Add network status context
        if !NetworkMonitor.shared.isConnected {
            self.errorMessage = "オフライン: \(errorMessage)"
        } else if NetworkMonitor.shared.shouldLimitDataUsage() {
            self.errorMessage = "制限モード: \(errorMessage)"
        } else {
            self.errorMessage = errorMessage
        }
        
        print("🚨 \(context)エラー: \(self.errorMessage ?? errorMessage)")
        
        // Auto-retry for certain network errors
        if isNetworkError && NetworkMonitor.shared.shouldRetryNetworkRequest(error) {
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

// MARK: - Supporting Types

enum BulletinBoardError: LocalizedError {
    case municipalityNotSelected
    case networkUnavailable
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .municipalityNotSelected:
            return "市町村が選択されていません"
        case .networkUnavailable:
            return "ネットワークに接続できません"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        }
    }
}

