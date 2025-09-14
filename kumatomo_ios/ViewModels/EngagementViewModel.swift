import Foundation
import SwiftUI

@MainActor
class EngagementViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Collections
    @Published var likedPosts: [Post] = []
    @Published var bookmarkedPosts: [Post] = []
    
    // Loading States
    @Published var isLoadingLikedPosts: Bool = false
    @Published var isLoadingBookmarkedPosts: Bool = false
    @Published var isRefreshingLikedPosts: Bool = false
    @Published var isRefreshingBookmarkedPosts: Bool = false
    
    // Engagement Action States
    @Published var likingPostIds: Set<Int> = []
    @Published var bookmarkingPostIds: Set<Int> = []
    
    // Error Handling
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    
    // Success Feedback
    @Published var successMessage: String = ""
    @Published var showSuccessMessage: Bool = false
    
    // Pagination Support
    @Published var hasMoreLikedPosts: Bool = true
    @Published var hasMoreBookmarkedPosts: Bool = true
    @Published var likedPostsPage: Int = 1
    @Published var bookmarkedPostsPage: Int = 1
    
    // MARK: - Services
    
    private let engagementAPIService = EngagementAPIService.shared
    private let postAPIService = PostAPIService.shared
    
    // MARK: - Constants
    
    private let postsPerPage = 20
    
    // MARK: - Computed Properties
    
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
    
    // MARK: - Initialization
    
    init() {
        print("🎯 EngagementViewModel初期化")
    }
    
    // MARK: - Liked Posts Management
    
    /// Load liked posts from API
    /// - Parameter refresh: Whether this is a refresh operation (clears existing data)
    func loadLikedPosts(refresh: Bool = false) async {
        // Prevent multiple simultaneous loads
        guard !isLoadingLikedPosts && !isRefreshingLikedPosts else {
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
        
        print("📖 いいねした投稿読み込み開始 (ページ: \(likedPostsPage), リフレッシュ: \(refresh))")
        
        do {
            let fetchedPosts = try await engagementAPIService.fetchLikedPosts()
            
            if refresh {
                likedPosts = fetchedPosts
            } else {
                // For pagination, append new posts (avoiding duplicates)
                let newPosts = fetchedPosts.filter { newPost in
                    !likedPosts.contains { existingPost in
                        existingPost.id == newPost.id
                    }
                }
                likedPosts.append(contentsOf: newPosts)
            }
            
            // Update pagination state
            hasMoreLikedPosts = fetchedPosts.count >= postsPerPage
            if !refresh && hasMoreLikedPosts {
                likedPostsPage += 1
            }
            
            print("✅ いいねした投稿読み込み成功: \(fetchedPosts.count)件 (合計: \(likedPosts.count)件)")
            
        } catch let error as EngagementError {
            await handleEngagementError(error, context: "いいねした投稿読み込み")
        } catch {
            await handleGenericError(error, context: "いいねした投稿読み込み")
        }
        
        isLoadingLikedPosts = false
        isRefreshingLikedPosts = false
    }
    
    /// Refresh liked posts (clears existing data and reloads)
    func refreshLikedPosts() async {
        await loadLikedPosts(refresh: true)
    }
    
    /// Load more liked posts (pagination)
    func loadMoreLikedPosts() async {
        guard hasMoreLikedPosts && !isLoadingLikedPosts else { return }
        await loadLikedPosts(refresh: false)
    }
    
    // MARK: - Bookmarked Posts Management
    
    /// Load bookmarked posts from API
    /// - Parameter refresh: Whether this is a refresh operation (clears existing data)
    func loadBookmarkedPosts(refresh: Bool = false) async {
        // Prevent multiple simultaneous loads
        guard !isLoadingBookmarkedPosts && !isRefreshingBookmarkedPosts else {
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
        
        print("📖 ブックマークした投稿読み込み開始 (ページ: \(bookmarkedPostsPage), リフレッシュ: \(refresh))")
        
        do {
            let fetchedPosts = try await engagementAPIService.fetchBookmarkedPosts()
            
            if refresh {
                bookmarkedPosts = fetchedPosts
            } else {
                // For pagination, append new posts (avoiding duplicates)
                let newPosts = fetchedPosts.filter { newPost in
                    !bookmarkedPosts.contains { existingPost in
                        existingPost.id == newPost.id
                    }
                }
                bookmarkedPosts.append(contentsOf: newPosts)
            }
            
            // Update pagination state
            hasMoreBookmarkedPosts = fetchedPosts.count >= postsPerPage
            if !refresh && hasMoreBookmarkedPosts {
                bookmarkedPostsPage += 1
            }
            
            print("✅ ブックマークした投稿読み込み成功: \(fetchedPosts.count)件 (合計: \(bookmarkedPosts.count)件)")
            
        } catch let error as EngagementError {
            await handleEngagementError(error, context: "ブックマークした投稿読み込み")
        } catch {
            await handleGenericError(error, context: "ブックマークした投稿読み込み")
        }
        
        isLoadingBookmarkedPosts = false
        isRefreshingBookmarkedPosts = false
    }
    
    /// Refresh bookmarked posts (clears existing data and reloads)
    func refreshBookmarkedPosts() async {
        await loadBookmarkedPosts(refresh: true)
    }
    
    /// Load more bookmarked posts (pagination)
    func loadMoreBookmarkedPosts() async {
        guard hasMoreBookmarkedPosts && !isLoadingBookmarkedPosts else { return }
        await loadBookmarkedPosts(refresh: false)
    }
    
    // MARK: - Like Toggle Actions
    
    /// Toggle like status for a post with optimistic updates
    /// - Parameter post: The post to toggle like status for
    func toggleLike(for post: Post) async {
        // Prevent multiple simultaneous requests for the same post
        guard !likingPostIds.contains(post.id) else {
            print("⚠️ 投稿ID \(post.id) のいいね処理中 - スキップ")
            return
        }
        
        likingPostIds.insert(post.id)
        clearError()
        
        // Store original values for rollback
        let originalIsLiked = post.isLikedByCurrentUser ?? false
        let originalLikeCount = post.likeCount ?? 0
        
        // Optimistic update in collections
        let newIsLiked = !originalIsLiked
        let newLikeCount = originalIsLiked ? max(0, originalLikeCount - 1) : originalLikeCount + 1
        
        updatePostInCollections(postId: post.id) { post in
            post.updateLikeStatus(isLiked: newIsLiked, likeCount: newLikeCount)
        }
        
        print("🔄 いいね最適化更新: 投稿ID \(post.id) - \(newIsLiked ? "いいね" : "いいね解除") (カウント: \(newLikeCount))")
        
        // API call with rollback capability
        let result = await engagementAPIService.optimisticToggleLike(
            postId: post.id,
            currentState: originalIsLiked,
            currentCount: originalLikeCount
        )
        
        if result.success, let response = result.response {
            // Update with server response
            updatePostInCollections(postId: post.id) { post in
                post.updateLikeStatus(isLiked: response.isLiked, likeCount: response.likeCount)
            }
            
            // If post was unliked, remove from liked posts collection
            if !response.isLiked {
                likedPosts.removeAll { $0.id == post.id }
            }
            
            await showSuccess(response.isLiked ? "いいねしました" : "いいねを取り消しました")
            print("✅ いいね更新成功: 投稿ID \(post.id) - \(response.isLiked ? "いいね" : "いいね解除") (サーバーカウント: \(response.likeCount))")
            
        } else {
            // Rollback on failure
            updatePostInCollections(postId: post.id) { post in
                post.updateLikeStatus(isLiked: originalIsLiked, likeCount: originalLikeCount)
            }
            
            if let error = result.error {
                await handleEngagementError(error, context: "いいね切り替え")
            }
            print("❌ いいね更新失敗: 投稿ID \(post.id) - ロールバック実行")
        }
        
        likingPostIds.remove(post.id)
    }
    
    // MARK: - Bookmark Toggle Actions
    
    /// Toggle bookmark status for a post with optimistic updates
    /// - Parameter post: The post to toggle bookmark status for
    func toggleBookmark(for post: Post) async {
        // Prevent multiple simultaneous requests for the same post
        guard !bookmarkingPostIds.contains(post.id) else {
            print("⚠️ 投稿ID \(post.id) のブックマーク処理中 - スキップ")
            return
        }
        
        bookmarkingPostIds.insert(post.id)
        clearError()
        
        // Store original values for rollback
        let originalIsBookmarked = post.isBookmarkedByCurrentUser ?? false
        let originalBookmarkCount = post.bookmarkCount ?? 0
        
        // Optimistic update in collections
        let newIsBookmarked = !originalIsBookmarked
        let newBookmarkCount = originalIsBookmarked ? max(0, originalBookmarkCount - 1) : originalBookmarkCount + 1
        
        updatePostInCollections(postId: post.id) { post in
            post.updateBookmarkStatus(isBookmarked: newIsBookmarked, bookmarkCount: newBookmarkCount)
        }
        
        print("🔄 ブックマーク最適化更新: 投稿ID \(post.id) - \(newIsBookmarked ? "ブックマーク" : "ブックマーク解除") (カウント: \(newBookmarkCount))")
        
        // API call with rollback capability
        let result = await engagementAPIService.optimisticToggleBookmark(
            postId: post.id,
            currentState: originalIsBookmarked,
            currentCount: originalBookmarkCount
        )
        
        if result.success, let response = result.response {
            // Update with server response
            updatePostInCollections(postId: post.id) { post in
                post.updateBookmarkStatus(isBookmarked: response.isBookmarked, bookmarkCount: response.bookmarkCount)
            }
            
            // If post was unbookmarked, remove from bookmarked posts collection
            if !response.isBookmarked {
                bookmarkedPosts.removeAll { $0.id == post.id }
            }
            
            await showSuccess(response.isBookmarked ? "ブックマークしました" : "ブックマークを取り消しました")
            print("✅ ブックマーク更新成功: 投稿ID \(post.id) - \(response.isBookmarked ? "ブックマーク" : "ブックマーク解除") (サーバーカウント: \(response.bookmarkCount))")
            
        } else {
            // Rollback on failure
            updatePostInCollections(postId: post.id) { post in
                post.updateBookmarkStatus(isBookmarked: originalIsBookmarked, bookmarkCount: originalBookmarkCount)
            }
            
            if let error = result.error {
                await handleEngagementError(error, context: "ブックマーク切り替え")
            }
            print("❌ ブックマーク更新失敗: 投稿ID \(post.id) - ロールバック実行")
        }
        
        bookmarkingPostIds.remove(post.id)
    }
    
    // MARK: - Utility Methods
    
    /// Update a post in both collections
    /// - Parameters:
    ///   - postId: The ID of the post to update
    ///   - updateBlock: The update block to apply to the post
    private func updatePostInCollections(postId: Int, updateBlock: (inout Post) -> Void) {
        // Update in liked posts collection
        if let index = likedPosts.firstIndex(where: { $0.id == postId }) {
            updateBlock(&likedPosts[index])
        }
        
        // Update in bookmarked posts collection
        if let index = bookmarkedPosts.firstIndex(where: { $0.id == postId }) {
            updateBlock(&bookmarkedPosts[index])
        }
    }
    
    /// Check if a post is currently being liked
    /// - Parameter postId: The ID of the post to check
    /// - Returns: True if the post is currently being liked
    func isLiking(postId: Int) -> Bool {
        return likingPostIds.contains(postId)
    }
    
    /// Check if a post is currently being bookmarked
    /// - Parameter postId: The ID of the post to check
    /// - Returns: True if the post is currently being bookmarked
    func isBookmarking(postId: Int) -> Bool {
        return bookmarkingPostIds.contains(postId)
    }
    
    /// Get a post from either collection by ID
    /// - Parameter postId: The ID of the post to find
    /// - Returns: The post if found in either collection
    func getPost(byId postId: Int) -> Post? {
        return likedPosts.first { $0.id == postId } ?? 
               bookmarkedPosts.first { $0.id == postId }
    }
    
    /// Remove a post from both collections (useful when post is deleted)
    /// - Parameter postId: The ID of the post to remove
    func removePost(withId postId: Int) {
        likedPosts.removeAll { $0.id == postId }
        bookmarkedPosts.removeAll { $0.id == postId }
        print("🗑️ 投稿ID \(postId) をコレクションから削除")
    }
    
    /// Reset all state
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
    
    /// Clear error state
    private func clearError() {
        errorMessage = nil
        showErrorAlert = false
    }
    
    /// Clear success state
    private func clearSuccess() {
        successMessage = ""
        showSuccessMessage = false
    }
    
    /// Show success message
    /// - Parameter message: The success message to show
    private func showSuccess(_ message: String) async {
        successMessage = message
        showSuccessMessage = true
        
        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showSuccessMessage = false
        }
    }
    
    // MARK: - Error Handling
    
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

// MARK: - Extensions

extension EngagementViewModel {
    /// Get formatted counts for display
    var formattedCounts: (likedPosts: String, bookmarkedPosts: String) {
        let likedCount = formatCount(likedPosts.count)
        let bookmarkedCount = formatCount(bookmarkedPosts.count)
        
        return (likedPosts: likedCount, bookmarkedPosts: bookmarkedCount)
    }
    
    /// Format count for display (e.g., 1200 -> "1.2K")
    /// - Parameter count: The count to format
    /// - Returns: Formatted string
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
    
    /// Get engagement summary for collections
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
    
    /// Check if collections are empty
    var hasNoEngagement: Bool {
        return likedPosts.isEmpty && bookmarkedPosts.isEmpty
    }
    
    /// Get total engagement count
    var totalEngagementCount: Int {
        return likedPosts.count + bookmarkedPosts.count
    }
}