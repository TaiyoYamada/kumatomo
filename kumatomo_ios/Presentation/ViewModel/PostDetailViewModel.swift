import Foundation
import SwiftUI
import UIKit
import Resolver

@MainActor
class PostDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var post: Post?
    @Published var comments: [Comment] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingComments: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    
    // Engagement loading states
    @Published var isTogglingLike: Bool = false
    @Published var isTogglingBookmark: Bool = false
    @Published var isAddingComment: Bool = false
    
    // Comment composition
    @Published var commentText: String = ""
    @Published var selectedCommentImage: UIImage?
    @Published var showImagePicker: Bool = false
    
    // MARK: - Services
    
    @Injected var postRepository: PostRepository
    @Injected var commentRepository: CommentRepository
    @Injected var engagementRepository: EngagementRepository
    @Injected var imageUploader: ImageUploadRepository
    @Injected var authRepository: AuthRepository
    
    // MARK: - Computed Properties
    
    var canAddComment: Bool {
        let hasText = !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = selectedCommentImage != nil
        return (hasText || hasImage) && !isAddingComment
    }
    
    var commentCharacterCount: Int {
        return commentText.count
    }
    
    var isCommentOverLimit: Bool {
        return commentText.count > 500
    }
    
    // MARK: - Post Detail Loading
    
    /// Load post details with engagement data
    /// - Parameter postId: The ID of the post to load
    func loadPostDetail(postId: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPost = try await postRepository.fetchPost(postId: postId)
            post = fetchedPost
            print("✅ 投稿詳細読み込み成功: ID \(postId)")
            print("📊 エンゲージメント: いいね\(fetchedPost.likeCount ?? 0)件, ブックマーク\(fetchedPost.bookmarkCount ?? 0)件, コメント\(fetchedPost.commentCount ?? 0)件")
        } catch let error as PostAPIError {
            await handlePostAPIError(error, context: "投稿詳細読み込み")
        } catch {
            await handleGenericError(error, context: "投稿詳細読み込み")
        }
        
        isLoading = false
    }
    
    /// Refresh post details
    func refreshPostDetail() async {
        guard let currentPost = post else { return }
        await loadPostDetail(postId: currentPost.id)
    }
    
    // MARK: - Comments Loading
    
    /// Load comments for the current post
    /// - Parameter postId: The ID of the post to load comments for
    func loadComments(postId: Int) async {
        isLoadingComments = true
        errorMessage = nil
        
        do {
            let fetchedComments = try await commentRepository.fetchComments(postId: postId)
            comments = fetchedComments.sorted { $0.createdAt < $1.createdAt }
            print("✅ コメント読み込み成功: \(fetchedComments.count)件")
        } catch let error as CommentError {
            await handleCommentError(error, context: "コメント読み込み")
        } catch {
            await handleGenericError(error, context: "コメント読み込み")
        }
        
        isLoadingComments = false
    }
    
    /// Refresh comments for the current post
    func refreshComments() async {
        guard let currentPost = post else { return }
        await loadComments(postId: currentPost.id)
    }
    
    // MARK: - Like Functionality
    
    /// Toggle like status with optimistic updates
    func toggleLike() async {
        guard var currentPost = post else {
            errorMessage = "投稿が見つかりません"
            return
        }
        
        // Prevent multiple simultaneous requests
        guard !isTogglingLike else { return }
        
        isTogglingLike = true
        errorMessage = nil
        
        // Store original values for rollback
        let originalIsLiked = currentPost.isLikedByCurrentUser ?? false
        let originalLikeCount = currentPost.likeCount ?? 0
        
        // Optimistic update
        let newIsLiked = !originalIsLiked
        let newLikeCount = originalIsLiked ? max(0, originalLikeCount - 1) : originalLikeCount + 1
        
        currentPost.updateLikeStatus(isLiked: newIsLiked, likeCount: newLikeCount)
        post = currentPost
        
        print("🔄 いいね最適化更新: \(newIsLiked ? "いいね" : "いいね解除") (カウント: \(newLikeCount))")
        
        // API call with rollback capability
        let result = await engagementRepository.optimisticToggleLike(
            postId: currentPost.id,
            currentState: originalIsLiked,
            currentCount: originalLikeCount
        )
        
        if result.success, let response = result.response {
            // Update with server response
            currentPost.updateLikeStatus(isLiked: response.isLiked, likeCount: response.likeCount)
            post = currentPost
            print("✅ いいね更新成功: \(response.isLiked ? "いいね" : "いいね解除") (サーバーカウント: \(response.likeCount))")
        } else {
            // Rollback on failure
            currentPost.updateLikeStatus(isLiked: originalIsLiked, likeCount: originalLikeCount)
            post = currentPost
            
            if let error = result.error {
                await handleEngagementError(error, context: "いいね切り替え")
            }
            print("❌ いいね更新失敗 - ロールバック実行")
        }
        
        isTogglingLike = false
    }
    
    // MARK: - Bookmark Functionality
    
    /// Toggle bookmark status with optimistic updates
    func toggleBookmark() async {
        guard var currentPost = post else {
            errorMessage = "投稿が見つかりません"
            return
        }
        
        // Prevent multiple simultaneous requests
        guard !isTogglingBookmark else { return }
        
        isTogglingBookmark = true
        errorMessage = nil
        
        // Store original values for rollback
        let originalIsBookmarked = currentPost.isBookmarkedByCurrentUser ?? false
        let originalBookmarkCount = currentPost.bookmarkCount ?? 0
        
        // Optimistic update
        let newIsBookmarked = !originalIsBookmarked
        let newBookmarkCount = originalIsBookmarked ? max(0, originalBookmarkCount - 1) : originalBookmarkCount + 1
        
        currentPost.updateBookmarkStatus(isBookmarked: newIsBookmarked, bookmarkCount: newBookmarkCount)
        post = currentPost
        
        print("🔄 ブックマーク最適化更新: \(newIsBookmarked ? "ブックマーク" : "ブックマーク解除") (カウント: \(newBookmarkCount))")
        
        // API call with rollback capability
        let result = await engagementRepository.optimisticToggleBookmark(
            postId: currentPost.id,
            currentState: originalIsBookmarked,
            currentCount: originalBookmarkCount
        )
        
        if result.success, let response = result.response {
            // Update with server response
            currentPost.updateBookmarkStatus(isBookmarked: response.isBookmarked, bookmarkCount: response.bookmarkCount)
            post = currentPost
            print("✅ ブックマーク更新成功: \(response.isBookmarked ? "ブックマーク" : "ブックマーク解除") (サーバーカウント: \(response.bookmarkCount))")
        } else {
            // Rollback on failure
            currentPost.updateBookmarkStatus(isBookmarked: originalIsBookmarked, bookmarkCount: originalBookmarkCount)
            post = currentPost
            
            if let error = result.error {
                await handleEngagementError(error, context: "ブックマーク切り替え")
            }
            print("❌ ブックマーク更新失敗 - ロールバック実行")
        }
        
        isTogglingBookmark = false
    }
    
    // MARK: - Comment Functionality
    
    /// Add a new comment with text and/or image
    /// - Parameters:
    ///   - text: The comment text content
    ///   - image: Optional image to attach to the comment
    func addComment(_ text: String, image: UIImage? = nil) async {
        guard let currentPost = post else {
            errorMessage = "投稿が見つかりません"
            return
        }
        
        // Validate input
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || image != nil else {
            errorMessage = "コメント内容または画像を入力してください"
            return
        }
        
        guard trimmedText.count <= 500 else {
            errorMessage = "コメントが長すぎます（500文字以内）"
            return
        }
        
        // Prevent multiple simultaneous requests
        guard !isAddingComment else { return }
        
        isAddingComment = true
        errorMessage = nil
        
        do {
            let imageData = image?.jpegData(compressionQuality: 0.8)
            let newComment = try await commentRepository.createComment(
                postId: currentPost.id,
                content: trimmedText,
                imageData: imageData
            )
            
            // Add comment to local list
            comments.append(newComment)
            comments.sort { $0.createdAt < $1.createdAt }
            
            // Update post comment count
            var updatedPost = currentPost
            updatedPost.commentCount = (updatedPost.commentCount ?? 0) + 1
            post = updatedPost
            
            // Clear form
            clearCommentForm()
            
            // Show success message
            await showSuccess("コメントを投稿しました")
            
            print("✅ コメント追加成功: ID \(newComment.id)")
            
        } catch let error as CommentError {
            await handleCommentError(error, context: "コメント投稿")
        } catch {
            await handleGenericError(error, context: "コメント投稿")
        }
        
        isAddingComment = false
    }
    
    /// Add comment using current form state
    func submitComment() async {
        await addComment(commentText, image: selectedCommentImage)
    }
    
    /// Clear comment composition form
    func clearCommentForm() {
        commentText = ""
        selectedCommentImage = nil
    }
    
    /// Remove comment image
    func removeCommentImage() {
        selectedCommentImage = nil
    }
    
    /// Set comment image
    /// - Parameter image: The image to set
    func setCommentImage(_ image: UIImage) {
        selectedCommentImage = image
    }
    
    // MARK: - Validation
    
    /// Validate comment content
    /// - Parameter content: The content to validate
    /// - Returns: Validation result with error message if invalid
    func validateCommentContent(_ content: String) -> (isValid: Bool, errorMessage: String?) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedContent.isEmpty && selectedCommentImage == nil {
            return (false, "コメント内容を入力してください")
        }
        
        if trimmedContent.count > 500 {
            return (false, "コメントが長すぎます（500文字以内）")
        }
        
        return (true, nil)
    }
    
    // MARK: - Utility Methods
    
    /// Reset all state
    func reset() {
        post = nil
        comments = []
        isLoading = false
        isLoadingComments = false
        errorMessage = nil
        showSuccessMessage = false
        successMessage = ""
        isTogglingLike = false
        isTogglingBookmark = false
        isAddingComment = false
        clearCommentForm()
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
    
    private func handlePostAPIError(_ error: PostAPIError, context: String) async {
        let message: String
        
        switch error {
        case .invalidURL:
            message = "無効なURLです"
        case .networkError(let err):
            message = "ネットワークエラー: \(err.localizedDescription)"
        case .invalidResponse:
            message = "無効なレスポンスです"
        case .decodingError(let err):
            message = "データの読み込みに失敗しました: \(err.localizedDescription)"
        case .apiError(let statusCode, let apiMessage):
            switch statusCode {
            case 401:
                message = "認証が必要です"
            case 403:
                message = "アクセス権限がありません"
            case 404:
                message = "投稿が見つかりません"
            case 429:
                message = "リクエストが多すぎます。しばらく待ってからお試しください"
            default:
                message = "APIエラー（\(statusCode)）: \(apiMessage)"
            }
        case .serverError(let serverMessage):
            message = "サーバーエラー: \(serverMessage)"
        case .unknownError(let err):
            message = "不明なエラー: \(err.localizedDescription)"
        case .timeout:
            message = "リクエストがタイムアウトしました"
        case .engagementDataError(let engagementMessage):
            message = "エンゲージメントデータエラー: \(engagementMessage)"
        case .authenticationRequired:
            message = "認証が必要です"
        case .postNotFound:
            message = "投稿が見つかりません"
        case .insufficientPermissions:
            message = "権限が不足しています"
        }
        
        errorMessage = "\(context)エラー: \(message)"
        print("🚨 [\(context)] PostAPIError: \(message)")
    }
    
    private func handleCommentError(_ error: CommentError, context: String) async {
        errorMessage = "\(context)エラー: \(error.localizedDescription)"
        print("🚨 [\(context)] CommentError: \(error.localizedDescription)")
    }
    
    private func handleEngagementError(_ error: EngagementError, context: String) async {
        errorMessage = "\(context)エラー: \(error.localizedDescription)"
        print("🚨 [\(context)] EngagementError: \(error.localizedDescription)")
    }
    
    private func handleGenericError(_ error: Error, context: String) async {
        errorMessage = "\(context)エラー: \(error.localizedDescription)"
        print("🚨 [\(context)] GenericError: \(error.localizedDescription)")
    }
}

// MARK: - Extensions

extension PostDetailViewModel {
    /// Get formatted engagement counts for display
    var formattedEngagementCounts: (likes: String, comments: String, bookmarks: String) {
        let likes = formatCount(post?.likeCount ?? 0)
        let comments = formatCount(post?.commentCount ?? 0)
        let bookmarks = formatCount(post?.bookmarkCount ?? 0)
        
        return (likes: likes, comments: comments, bookmarks: bookmarks)
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
    
    /// Check if current user is the post owner
    var isCurrentUserPostOwner: Bool {
        guard let post = post,
              let currentUser = authRepository.currentUser else {
            return false
        }
        return post.userId == currentUser.id
    }
    
    /// Get engagement summary text
    var engagementSummary: String {
        guard let post = post else { return "" }
        return post.engagementSummary
    }
}
