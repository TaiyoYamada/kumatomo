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
    
    private let postAPIService = PostAPIService()
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
        switch activeTab {
        case .all:
            return try await postAPIService.fetchAllPosts(page: page, limit: postsPerPage)
        case .municipality:
            guard let municipality = selectedMunicipality else {
                throw BulletinBoardError.municipalityNotSelected
            }
            return try await postAPIService.fetchMunicipalityPosts(
                municipality: municipality,
                page: page,
                limit: postsPerPage
            )
        case .following:
            return try await postAPIService.fetchFollowingPosts(page: page, limit: postsPerPage)
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
        
        do {
            // Send to server
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
            
        } catch {
            // Rollback optimistic update
            reactionUpdates.removeValue(forKey: postId)
            userReactions[postId] = currentUserReaction
            
            updatePostInList(postId: postId) { post in
                post.reactions = post.reactions
                post.userReaction = currentUserReaction
            }
            
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
        
        do {
            // Send to server
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
            Task {
                await refreshPostsForCurrentTab()
            }
        }
    }
    
    private func loadUserPreferences() {
        // Load saved municipality preference
        selectedMunicipality = UserDefaults.standard.string(forKey: "selectedMunicipality")
        
        // Load bookmarked posts
        if let bookmarkedData = UserDefaults.standard.data(forKey: "bookmarkedPosts"),
           let bookmarked = try? JSONDecoder().decode(Set<Int>.self, from: bookmarkedData) {
            bookmarkedPosts = bookmarked
        }
    }
    
    private func saveUserPreferences() {
        // Save municipality preference
        UserDefaults.standard.set(selectedMunicipality, forKey: "selectedMunicipality")
        
        // Save bookmarked posts
        if let bookmarkedData = try? JSONEncoder().encode(bookmarkedPosts) {
            UserDefaults.standard.set(bookmarkedData, forKey: "bookmarkedPosts")
        }
    }
    
    private func handleError(_ error: Error, context: String) async {
        let errorMessage: String
        
        if let bulletinBoardError = error as? BulletinBoardError {
            errorMessage = bulletinBoardError.localizedDescription
        } else if let postAPIError = error as? PostAPIError {
            errorMessage = postAPIError.localizedDescription
        } else {
            errorMessage = "\(context)中にエラーが発生しました: \(error.localizedDescription)"
        }
        
        self.errorMessage = errorMessage
        print("🚨 \(context)エラー: \(errorMessage)")
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

// MARK: - API Extensions

extension PostAPIService {
    func fetchAllPosts(page: Int = 1, limit: Int = 20) async throws -> [Post] {
        // TODO: Implement paginated API call
        return try await fetchAllPosts()
    }
    
    func fetchMunicipalityPosts(municipality: String, page: Int = 1, limit: Int = 20) async throws -> [Post] {
        // TODO: Implement municipality-specific API call
        return try await fetchAllPosts()
    }
    
    func fetchFollowingPosts(page: Int = 1, limit: Int = 20) async throws -> [Post] {
        // TODO: Implement following-specific API call
        return try await fetchAllPosts()
    }
    
    func toggleReaction(postId: Int, reactionType: ReactionType) async throws -> (reactions: PostReactions, userReaction: ReactionType?) {
        // TODO: Implement reaction API call
        // For now, return mock data
        let reactions = PostReactions(thumbsUp: 5, drooling: 3, spicy: 1)
        return (reactions: reactions, userReaction: reactionType)
    }
    
    func toggleBookmark(postId: Int) async throws -> Bool {
        // TODO: Implement bookmark API call
        // For now, return mock data
        return true
    }
}