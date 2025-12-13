import Foundation
import SwiftUI
import UIKit
import Resolver
import Observation

// MARK: - PostDetailViewModel

@MainActor
@Observable
class PostDetailViewModel {

    var post: Post?
    var comments: [Comment] = []
    var isLoading: Bool = false
    var isLoadingComments: Bool = false
    var errorMessage: String?
    var showSuccessMessage: Bool = false
    var successMessage: String = ""

    var isTogglingLike: Bool = false
    var isTogglingBookmark: Bool = false
    var isAddingComment: Bool = false

    var commentText: String = ""
    var selectedCommentImage: UIImage?
    var showImagePicker: Bool = false

    @ObservationIgnored @Injected var fetchPostUseCase: FetchPostUseCase
    @ObservationIgnored @Injected var fetchCommentsUseCase: FetchCommentsUseCase
    @ObservationIgnored @Injected var createCommentUseCase: CreateCommentUseCase
    @ObservationIgnored @Injected var toggleLikeUseCase: ToggleLikeUseCase
    @ObservationIgnored @Injected var toggleBookmarkUseCase: ToggleBookmarkUseCase
    @ObservationIgnored @Injected var authRepository: AuthRepository

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

    func loadPostDetail(postId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedPost = try await fetchPostUseCase.execute(postId: postId)
            post = fetchedPost
            print("✅ 投稿詳細読み込み成功: ID \(postId)")
            print(
                "📊 エンゲージメント: いいね\(fetchedPost.likeCount ?? 0)件, ブックマーク\(fetchedPost.bookmarkCount ?? 0)件, コメント\(fetchedPost.commentCount ?? 0)件"
            )
        } catch let error as PostAPIError {
            await handlePostAPIError(error, context: "投稿詳細読み込み")
        } catch {
            await handleGenericError(error, context: "投稿詳細読み込み")
        }

        isLoading = false
    }

    func refreshPostDetail() async {
        guard let currentPost = post else { return }
        await loadPostDetail(postId: currentPost.id)
    }

    func loadComments(postId: Int) async {
        isLoadingComments = true
        errorMessage = nil

        do {
            let fetchedComments = try await fetchCommentsUseCase.execute(postId: postId)
            comments = fetchedComments.sorted { $0.createdAt < $1.createdAt }
            print("✅ コメント読み込み成功: \(fetchedComments.count)件")
        } catch let error as CommentError {
            await handleCommentError(error, context: "コメント読み込み")
        } catch {
            await handleGenericError(error, context: "コメント読み込み")
        }

        isLoadingComments = false
    }

    func refreshComments() async {
        guard let currentPost = post else { return }
        await loadComments(postId: currentPost.id)
    }

    func toggleLike() async {
        guard var currentPost = post else {
            errorMessage = "投稿が見つかりません"
            return
        }

        guard !isTogglingLike else { return }

        isTogglingLike = true
        errorMessage = nil

        let originalIsLiked = currentPost.isLikedByCurrentUser ?? false
        let originalLikeCount = currentPost.likeCount ?? 0

        let newIsLiked = !originalIsLiked
        let newLikeCount = originalIsLiked ? max(0, originalLikeCount - 1) : originalLikeCount + 1

        currentPost.updateLikeStatus(isLiked: newIsLiked, likeCount: newLikeCount)
        post = currentPost

        print("🔄 いいね最適化更新: \(newIsLiked ? "いいね" : "いいね解除") (カウント: \(newLikeCount))")

        let result = await toggleLikeUseCase.execute(
            postId: currentPost.id,
            currentState: originalIsLiked,
            currentCount: originalLikeCount
        )
        switch result {
        case let .success(response):
            currentPost.updateLikeStatus(isLiked: response.isLiked, likeCount: response.likeCount)
            post = currentPost
            print("✅ いいね更新成功: \(response.isLiked ? "いいね" : "いいね解除") (サーバーカウント: \(response.likeCount))")
        case let .failure(error):
            currentPost.updateLikeStatus(isLiked: originalIsLiked, likeCount: originalLikeCount)
            post = currentPost
            await handleEngagementError(error, context: "いいね切り替え")
            print("❌ いいね更新失敗 - ロールバック実行")
        }

        isTogglingLike = false
    }

    func toggleBookmark() async {
        guard var currentPost = post else {
            errorMessage = "投稿が見つかりません"
            return
        }

        guard !isTogglingBookmark else { return }

        isTogglingBookmark = true
        errorMessage = nil

        let originalIsBookmarked = currentPost.isBookmarkedByCurrentUser ?? false
        let originalBookmarkCount = currentPost.bookmarkCount ?? 0

        let newIsBookmarked = !originalIsBookmarked
        let newBookmarkCount = originalIsBookmarked ? max(0, originalBookmarkCount - 1) : originalBookmarkCount + 1

        currentPost.updateBookmarkStatus(isBookmarked: newIsBookmarked, bookmarkCount: newBookmarkCount)
        post = currentPost

        print("🔄 ブックマーク最適化更新: \(newIsBookmarked ? "ブックマーク" : "ブックマーク解除") (カウント: \(newBookmarkCount))")

        let result = await toggleBookmarkUseCase.execute(
            postId: currentPost.id,
            currentState: originalIsBookmarked,
            currentCount: originalBookmarkCount
        )
        switch result {
        case let .success(response):
            currentPost.updateBookmarkStatus(isBookmarked: response.isBookmarked, bookmarkCount: response.bookmarkCount)
            post = currentPost
            print(
                "✅ ブックマーク更新成功: \(response.isBookmarked ? "ブックマーク" : "ブックマーク解除") (サーバーカウント: \(response.bookmarkCount))"
            )
        case let .failure(error):
            currentPost.updateBookmarkStatus(isBookmarked: originalIsBookmarked, bookmarkCount: originalBookmarkCount)
            post = currentPost
            await handleEngagementError(error, context: "ブックマーク切り替え")
            print("❌ ブックマーク更新失敗 - ロールバック実行")
        }

        isTogglingBookmark = false
    }

    func addComment(_ text: String, image: UIImage? = nil) async {
        guard let currentPost = post else {
            errorMessage = "投稿が見つかりません"
            return
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || image != nil else {
            errorMessage = "コメント内容または画像を入力してください"
            return
        }

        guard trimmedText.count <= 500 else {
            errorMessage = "コメントが長すぎます（500文字以内）"
            return
        }

        guard !isAddingComment else { return }

        isAddingComment = true
        errorMessage = nil

        do {
            let imageData = image?.jpegData(compressionQuality: 0.8)
            let newComment = try await createCommentUseCase.execute(
                postId: currentPost.id,
                content: trimmedText,
                imageData: imageData
            )

            comments.append(newComment)
            comments.sort { $0.createdAt < $1.createdAt }

            var updatedPost = currentPost
            updatedPost.commentCount = (updatedPost.commentCount ?? 0) + 1
            post = updatedPost

            clearCommentForm()

            await showSuccess("コメントを投稿しました")

            print("✅ コメント追加成功: ID \(newComment.id)")

        } catch let error as CommentError {
            await handleCommentError(error, context: "コメント投稿")
        } catch {
            await handleGenericError(error, context: "コメント投稿")
        }

        isAddingComment = false
    }

    func submitComment() async {
        await addComment(commentText, image: selectedCommentImage)
    }

    func clearCommentForm() {
        commentText = ""
        selectedCommentImage = nil
    }

    func removeCommentImage() {
        selectedCommentImage = nil
    }

    func setCommentImage(_ image: UIImage) {
        selectedCommentImage = image
    }

    func validateCommentContent(_ content: String) -> (isValid: Bool, errorMessage: String?) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedContent.isEmpty, selectedCommentImage == nil {
            return (false, "コメント内容を入力してください")
        }

        if trimmedContent.count > 500 {
            return (false, "コメントが長すぎます（500文字以内）")
        }

        return (true, nil)
    }

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

    private func showSuccess(_ message: String) async {
        successMessage = message
        showSuccessMessage = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showSuccessMessage = false
        }
    }

    private func handlePostAPIError(_ error: PostAPIError, context: String) async {
        let message = switch error {
        case .invalidURL:
            "無効なURLです"
        case let .networkError(err):
            "ネットワークエラー: \(err.localizedDescription)"
        case .invalidResponse:
            "無効なレスポンスです"
        case let .decodingError(err):
            "データの読み込みに失敗しました: \(err.localizedDescription)"
        case let .apiError(statusCode, apiMessage):
            switch statusCode {
            case 401:
                "認証が必要です"
            case 403:
                "アクセス権限がありません"
            case 404:
                "投稿が見つかりません"
            case 429:
                "リクエストが多すぎます。しばらく待ってからお試しください"
            default:
                "APIエラー（\(statusCode)）: \(apiMessage)"
            }
        case let .serverError(serverMessage):
            "サーバーエラー: \(serverMessage)"
        case let .unknownError(err):
            "不明なエラー: \(err.localizedDescription)"
        case .timeout:
            "リクエストがタイムアウトしました"
        case let .engagementDataError(engagementMessage):
            "エンゲージメントデータエラー: \(engagementMessage)"
        case .authenticationRequired:
            "認証が必要です"
        case .postNotFound:
            "投稿が見つかりません"
        case .insufficientPermissions:
            "権限が不足しています"
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

extension PostDetailViewModel {
    var formattedEngagementCounts: (likes: String, comments: String, bookmarks: String) {
        let likes = formatCount(post?.likeCount ?? 0)
        let comments = formatCount(post?.commentCount ?? 0)
        let bookmarks = formatCount(post?.bookmarkCount ?? 0)

        return (likes: likes, comments: comments, bookmarks: bookmarks)
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

    var isCurrentUserPostOwner: Bool {
        guard let post,
              let currentUser = authRepository.currentUser else {
            return false
        }
        return post.userId == currentUser.id
    }

    var engagementSummary: String {
        guard let post else { return "" }
        return post.engagementSummary
    }
}
