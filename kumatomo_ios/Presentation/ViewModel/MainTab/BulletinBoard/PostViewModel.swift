import Foundation
import SwiftUI
import Combine
import Factory
import Observation

// MARK: - ValidationState

struct ValidationState {
    let isValid: Bool
    let errors: [PostError]
    let canPost: Bool

    var hasContentError: Bool {
        errors.contains { error in
            switch error {
            case .noContentOrImages, .contentOverLimit:
                return true
            default:
                return false
            }
        }
    }

    var hasTagError: Bool {
        errors.contains { error in
            switch error {
            case .noTagsSelected:
                return true
            default:
                return false
            }
        }
    }

    var primaryErrorMessage: String? {
        errors.first?.errorDescription
    }
}

// MARK: - ContentValidationState

enum ContentValidationState: Equatable {
    case empty
    case valid
    case warningLimit(currentCount: Int, maxCount: Int)
    case nearLimit(currentCount: Int, maxCount: Int)
    case overLimit(currentCount: Int, maxCount: Int)
}

// MARK: - TagValidationState

enum TagValidationState: Equatable {
    case noTagsSelected
    case valid
    case maxTagsReached
}

// MARK: - PostViewModel

@MainActor
@Observable
class PostViewModel {
    var postContent: String = ""
    var selectedImage: UIImage?
    var selectedImages: [UIImage] = []
    var imageURL: String?
    var tags: [String] = []
    var tagInput: String = ""

    var selectedTags: Set<String> = ["熊本県全体"]
    var availableTags: [String] { ["熊本県全体"] + City.allCases.map(\.displayName) }

    var posts: [Post] = []
    var userPosts: [Post] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var showSuccessModal: Bool = false
    var isSubmitting: Bool = false

    var activeTab: TabType = .all
    var selectedMunicipality: String?

    var isEditing: Bool = false
    var editingPost: Post?
    var showDeleteConfirmation: Bool = false
    var postToDelete: Post?
    var isDeleting: Bool = false
    var isUpdating: Bool = false

    @ObservationIgnored @Injected(\.fetchAllPostsUseCase) var fetchAllPostsUseCase
    @ObservationIgnored @Injected(\.fetchUserPostsUseCase) var fetchUserPostsUseCase
    @ObservationIgnored @Injected(\.fetchMunicipalityPostsUseCase) var fetchMunicipalityPostsUseCase
    @ObservationIgnored @Injected(\.fetchFollowingPostsUseCase) var fetchFollowingPostsUseCase
    @ObservationIgnored @Injected(\.fetchPostUseCase) var fetchPostUseCase
    @ObservationIgnored @Injected(\.createPostUseCase) var createPostUseCase
    @ObservationIgnored @Injected(\.createPostWithMultipleImagesUseCase) var createPostWithMultipleImagesUseCase
    @ObservationIgnored @Injected(\.updatePostUseCase) var updatePostUseCase
    @ObservationIgnored @Injected(\.deletePostUseCase) var deletePostUseCase
    @ObservationIgnored @Injected(\.authRepository) var authRepository

    var canPost: Bool {
        hasValidContent && hasValidTags && !isLoading && !isSubmitting
    }

    private var hasValidContent: Bool {
        let hasText = !postContent.isEmpty && postContent.count <= 300
        let hasImages = !selectedImages.isEmpty
        return hasText || hasImages
    }

    private var hasValidTags: Bool {
        !selectedTags.isEmpty
    }

    func validateContent() -> Result<Void, PostError> {
        let hasText = !postContent.isEmpty
        let hasImages = !selectedImages.isEmpty

        if !hasText, !hasImages {
            return .failure(.noContent)
        }

        if hasText, postContent.count > 300 {
            return .failure(.contentOverLimit(currentCount: postContent.count, maxCount: 300))
        }
        return .success(())
    }

    func validateImages() -> Result<Void, PostError> {
        if selectedImages.isEmpty {
            return .success(())
        }

        if selectedImages.count > 5 {
            return .failure(.tooManyImages(currentCount: selectedImages.count, maxCount: 5))
        }

        for image in selectedImages {
            if image.size.width == 0 || image.size.height == 0 {
                return .failure(.invalidImageData)
            }
        }

        return .success(())
    }

    func validateTags() -> Result<Void, PostError> {
        if selectedTags.isEmpty {
            return .failure(.noTagsSelected)
        }

        return .success(())
    }

    func validateForSubmission() -> Result<Void, PostError> {
        if isSubmitting {
            return .failure(.submissionInProgress)
        }

        switch validateContent() {
        case let .failure(error):
            return .failure(error)
        case .success:
            break
        }

        switch validateImages() {
        case let .failure(error):
            return .failure(error)
        case .success:
            break
        }

        switch validateTags() {
        case let .failure(error):
            return .failure(error)
        case .success:
            break
        }

        return .success(())
    }

    func getValidationState() -> ValidationState {
        let contentValidation = validateContent()
        let imageValidation = validateImages()
        let tagValidation = validateTags()

        var errors: [PostError] = []

        if case let .failure(error) = contentValidation {
            errors.append(error)
        }

        if case let .failure(error) = imageValidation {
            errors.append(error)
        }

        if case let .failure(error) = tagValidation {
            errors.append(error)
        }

        if isSubmitting {
            errors.append(.submissionInProgress)
        }

        return ValidationState(
            isValid: errors.isEmpty && !isSubmitting,
            errors: errors,
            canPost: canPost
        )
    }

    func getContentValidationState() -> ContentValidationState {
        let hasText = !postContent.isEmpty
        let hasImages = !selectedImages.isEmpty
        let isOverLimit = postContent.count > 500

        if !hasText, !hasImages {
            return .empty
        } else if isOverLimit {
            return .overLimit(currentCount: postContent.count, maxCount: 300)
        } else if postContent.count > 270 {
            return .nearLimit(currentCount: postContent.count, maxCount: 300)
        } else if postContent.count > 220 {
            return .warningLimit(currentCount: postContent.count, maxCount: 300)
        } else {
            return .valid
        }
    }

    func getTagValidationState() -> TagValidationState {
        if selectedTags.isEmpty {
            return .noTagsSelected
        } else if selectedTags.count >= 5 {
            return .maxTagsReached
        } else {
            return .valid
        }
    }

    func addTag() -> Result<Void, PostError> {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedTag.isEmpty {
            return .failure(.tagEmpty)
        }

        if tags.contains(trimmedTag) {
            return .failure(.duplicateTag(tagName: trimmedTag))
        }

        if tags.count >= 5 {
            return .failure(.tagLimitExceeded(currentCount: tags.count, maxCount: 5))
        }

        if trimmedTag.count > 20 {
            return .failure(.tagTooLong(tagName: trimmedTag, currentCount: trimmedTag.count, maxCount: 20))
        }

        tags.append(trimmedTag)
        tagInput = ""
        return .success(())
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            if selectedTags.count > 1 {
                selectedTags.remove(tag)
            }
        } else {
            if selectedTags.count < 5 {
                selectedTags.insert(tag)
            }
        }
    }

    func resetForm() {
        postContent = ""
        selectedImage = nil
        selectedImages = []
        imageURL = nil
        tags = []
        tagInput = ""
        selectedTags = ["熊本県全体"]
        errorMessage = nil
        showSuccessModal = false
        isEditing = false
        editingPost = nil
    }

    func fetchAllPosts() async {
        await performAsyncOperation { self.posts = try await self.fetchAllPostsUseCase.execute(page: nil, limit: nil) }
    }

    func fetchUserPosts(userId: Int) async {
        await performAsyncOperation { self.userPosts = try await self.fetchUserPostsUseCase.execute(
            userId: userId,
            page: nil,
            limit: nil
        ) }
    }

    func postPost(userId: Int, content: String) async -> Bool {
        switch validateForSubmission() {
        case let .failure(error):
            await handlePostError(error)
            return false
        case .success:
            break
        }

        isSubmitting = true
        isLoading = true
        errorMessage = nil
        showSuccessModal = false

        do {
            let imageData = selectedImage?.jpegData(compressionQuality: 0.7)
            let newPost = try await createPostUseCase.execute(
                userId: userId,
                content: content,
                tags: Array(selectedTags),
                imageData: imageData
            )

            await handleSuccessfulSubmission(newPost)
            return true

        } catch let error as PostAPIError {
            await handlePostAPIError(error)
        } catch let error as ImageUploadError {
            await handleImageUploadError(error)
        } catch {
            await handleGenericError(error, context: "ストーリー投稿")
        }

        isSubmitting = false
        return false
    }

    func createPostWithMultipleImages(userId: Int, content: String, images: [UIImage]) async -> Bool {
        switch validateForSubmission() {
        case let .failure(error):
            await handlePostError(error)
            return false
        case .success:
            break
        }

        isSubmitting = true
        isLoading = true
        errorMessage = nil
        showSuccessModal = false

        do {
            let datas: [Data] = images.compactMap { $0.jpegData(compressionQuality: 0.7) }
            let newPost = try await createPostWithMultipleImagesUseCase.execute(
                userId: userId,
                content: content,
                tags: Array(selectedTags),
                imageDatas: datas
            )

            await handleSuccessfulSubmission(newPost)
            return true

        } catch let error as PostAPIError {
            await handlePostAPIError(error)
        } catch let error as ImageUploadError {
            await handleImageUploadError(error)
        } catch {
            await handleGenericError(error, context: "投稿作成")
        }

        isSubmitting = false
        return false
    }

    func startEditing(_ post: Post) {
        editingPost = post
        postContent = post.content
        tags = post.tags ?? []
        if let postTags = post.tags, !postTags.isEmpty {
            selectedTags = Set(postTags)
        } else {
            selectedTags = ["熊本県全体"]
        }
        isEditing = true
    }

    func cancelEditing() {
        resetForm()
    }

    func updatePost() async -> Bool {
        guard let post = editingPost else {
            errorMessage = "編集対象の投稿が見つかりません"
            return false
        }

        switch validateForSubmission() {
        case let .failure(error):
            await handleValidationError(error)
            return false
        case .success:
            break
        }

        isUpdating = true
        isLoading = true
        errorMessage = nil

        let originalPost = post
        let originalIndex = posts.firstIndex { $0.id == post.id }
        let originalUserIndex = userPosts.firstIndex { $0.id == post.id }

        var updatedPost = post
        updatedPost.content = postContent
        updatedPost.tags = selectedTags.isEmpty ? nil : Array(selectedTags)
        updatedPost.updatedAt = Date()

        if let index = originalIndex {
            posts[index] = updatedPost
        }
        if let index = originalUserIndex {
            userPosts[index] = updatedPost
        }

        do {
            let serverPost = try await updatePostUseCase.execute(
                postId: post.id,
                content: postContent,
                tags: Array(selectedTags)
            )

            if let index = originalIndex {
                posts[index] = serverPost
            }
            if let index = originalUserIndex {
                userPosts[index] = serverPost
            }

            await handleSuccessfulUpdate()
            return true

        } catch let error as PostAPIError {
            if let index = originalIndex {
                posts[index] = originalPost
            }
            if let index = originalUserIndex {
                userPosts[index] = originalPost
            }

            await handlePostAPIError(error)
        } catch {
            if let index = originalIndex {
                posts[index] = originalPost
            }
            if let index = originalUserIndex {
                userPosts[index] = originalPost
            }

            await handleGenericError(error, context: "投稿更新")
        }

        isUpdating = false
        return false
    }

    func confirmDelete(_ post: Post) {
        postToDelete = post
        showDeleteConfirmation = true
    }

    func cancelDelete() {
        postToDelete = nil
        showDeleteConfirmation = false
    }

    func deletePost() async -> Bool {
        guard let post = postToDelete else {
            errorMessage = "削除対象の投稿が見つかりません"
            return false
        }

        isDeleting = true
        isLoading = true
        errorMessage = nil

        let originalIndex = posts.firstIndex { $0.id == post.id }
        let originalUserIndex = userPosts.firstIndex { $0.id == post.id }

        posts.removeAll { $0.id == post.id }
        userPosts.removeAll { $0.id == post.id }

        do {
            try await deletePostUseCase.execute(postId: post.id)

            await handleSuccessfulDeletion()
            return true

        } catch let error as PostAPIError {
            if let index = originalIndex {
                posts.insert(post, at: index)
            }
            if let index = originalUserIndex {
                userPosts.insert(post, at: index)
            }

            await handlePostAPIError(error)
        } catch {
            if let index = originalIndex {
                posts.insert(post, at: index)
            }
            if let index = originalUserIndex {
                userPosts.insert(post, at: index)
            }

            await handleGenericError(error, context: "投稿削除")
        }

        isDeleting = false
        return false
    }

    func fetchPost(postId: Int) async -> Post? {
        isLoading = true
        errorMessage = nil

        do {
            let post = try await fetchPostUseCase.execute(postId: postId)
            isLoading = false
            return post
        } catch let error as PostAPIError {
            await handlePostAPIError(error)
            return nil
        } catch {
            await handleGenericError(error, context: "投稿取得")
            return nil
        }
    }

    func isPostOwner(_ post: Post) -> Bool {
        guard let currentUser = authRepository.currentUser else { return false }
        return post.userId == currentUser.id
    }

    private func handleSuccessfulUpdate() async {
        resetForm()

        isLoading = false
        isUpdating = false

        showSuccessModal = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showSuccessModal = false
        }
    }

    private func handleSuccessfulDeletion() async {
        postToDelete = nil
        showDeleteConfirmation = false

        isLoading = false
        isDeleting = false

        showSuccessModal = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showSuccessModal = false
        }
    }

    private func handleSuccessfulSubmission(_ newPost: Post) async {
        posts.insert(newPost, at: 0)
        userPosts.insert(newPost, at: 0)

        showSuccessModal = true
        isLoading = false
        isSubmitting = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.resetForm()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showSuccessModal = false
        }
    }

    private func performAsyncOperation(_ operation: @escaping () async throws -> some Any) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await operation()
            isLoading = false
        } catch let error as PostAPIError {
            await handlePostAPIError(error)
        } catch {
            await handleGenericError(error, context: "データ取得")
        }
    }

    private func handlePostError(_ error: PostError) async {
        errorMessage = error.localizedDescription
        print("🚨 PostError: \(error.localizedDescription)")
    }

    private func handlePostAPIError(_ error: PostAPIError) async {
        isLoading = false

        let apiError: APIError
        switch error {
        case .invalidURL:
            apiError = .invalidURL
        case let .networkError(err):
            apiError = .networkError(err)
        case .invalidResponse:
            apiError = .invalidResponse
        case let .decodingError(err):
            if let decodingError = err as? DecodingError {
                apiError = .decodingError(decodingError)
            } else {
                let context = DecodingError.Context(codingPath: [], debugDescription: err.localizedDescription)
                apiError = .decodingError(.dataCorrupted(context))
            }
        case let .apiError(statusCode, message):
            switch statusCode {
            case 401:
                apiError = .unauthorized
            case 403:
                apiError = .forbidden
            case 404:
                apiError = .notFound
            case 429:
                apiError = .rateLimitExceeded
            default:
                apiError = .apiError(statusCode: statusCode, message: message)
            }
        case let .serverError(message):
            apiError = .serverError(message: message)
        case let .unknownError(err):
            apiError = .unknownError(err)
        case .timeout:
            apiError = .timeout
        case let .engagementDataError(message):
            apiError = .serverError(message: "エンゲージメントデータエラー: \(message)")
            print("📊 エンゲージメントデータエラー: \(message)")
        case .authenticationRequired:
            apiError = .unauthorized
            print("🔐 認証が必要です")
        case .postNotFound:
            apiError = .notFound
            print("📝 投稿が見つかりません")
        case .insufficientPermissions:
            apiError = .forbidden
            print("🚫 権限が不足しています")
        }

        await handleAPIError(apiError)
    }

    private func handleAPIError(_ error: APIError) async {
        isLoading = false
        errorMessage = error.localizedDescription
        print("🚨 APIError: \(error.localizedDescription)")

        if let failureReason = error.failureReason {
            print("🔍 Failure reason: \(failureReason)")
        }

        if let recoverySuggestion = error.recoverySuggestion {
            print("💡 Recovery suggestion: \(recoverySuggestion)")
        }
    }

    private func handleImageUploadError(_ error: ImageUploadError) async {
        isLoading = false
        errorMessage = error.localizedDescription
        print("🚨 ImageUploadError: \(error.localizedDescription)")

        if let failureReason = error.failureReason {
            print("🔍 Failure reason: \(failureReason)")
        }

        if let recoverySuggestion = error.recoverySuggestion {
            print("💡 Recovery suggestion: \(recoverySuggestion)")
        }
    }

    private func handleValidationError(_ error: PostError) async {
        errorMessage = error.localizedDescription
        print("🚨 ValidationError: \(error.localizedDescription)")

        if let failureReason = error.failureReason {
            print("🔍 Failure reason: \(failureReason)")
        }

        if let recoverySuggestion = error.recoverySuggestion {
            print("💡 Recovery suggestion: \(recoverySuggestion)")
        }
    }

    private func handleGenericError(_ error: Error, context: String) async {
        isLoading = false
        errorMessage = "\(context)エラー: \(error.localizedDescription)"
        print("🚨 \(context)エラー: \(error.localizedDescription)")
    }
}

extension PostViewModel {
    func changeTab(_ tab: TabType) {
        activeTab = tab
        Task {
            await fetchPostsForCurrentTab()
        }
    }

    func changeMunicipality(_ municipality: String) {
        selectedMunicipality = municipality
        if activeTab == .municipality {
            Task {
                await fetchPostsForCurrentTab()
            }
        }
    }

    private func fetchPostsForCurrentTab() async {
        switch activeTab {
        case .all:
            await fetchAllPosts()
        case .municipality:
            if let municipality = selectedMunicipality {
                await fetchMunicipalityPosts(municipality: municipality)
            }
        case .following:
            await fetchFollowingPosts()
        }
    }

    private func fetchMunicipalityPosts(municipality: String) async {
        await performAsyncOperation {
            self.posts = try await self.fetchAllPostsUseCase.execute(page: nil, limit: nil)
        }
    }

    private func fetchFollowingPosts() async {
        await performAsyncOperation {
            self.posts = try await self.fetchAllPostsUseCase.execute(page: nil, limit: nil)
        }
    }
}
