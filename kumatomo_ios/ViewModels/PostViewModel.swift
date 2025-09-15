import Foundation
import SwiftUI
import Combine

// MARK: - Validation State
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

// MARK: - Content Validation State
enum ContentValidationState: Equatable {
    case empty
    case valid
    case warningLimit(currentCount: Int, maxCount: Int)
    case nearLimit(currentCount: Int, maxCount: Int)
    case overLimit(currentCount: Int, maxCount: Int)
}

// MARK: - Tag Validation State
enum TagValidationState: Equatable {
    case noTagsSelected
    case valid
    case maxTagsReached
}

@MainActor
class PostViewModel: ObservableObject {
    @Published var postContent: String = ""
    @Published var selectedImage: UIImage? // Deprecated: use selectedImages instead
    @Published var selectedImages: [UIImage] = []
    @Published var selectedShop: Shop?
    @Published var imageURL: String?
    @Published var tags: [String] = [] // Deprecated: use selectedTags instead
    @Published var tagInput: String = ""
    
    // New tag functionality
    @Published var selectedTags: Set<String> = ["熊本県全体"]
    var availableTags: [String] { ["熊本県全体"] + Municipality.allCases.map { $0.displayName } }
    
    @Published var posts: [Post] = []
    @Published var userPosts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessModal: Bool = false
    @Published var isSubmitting: Bool = false
    
    // Bulletin Board specific properties
    @Published var activeTab: TabType = .all
    @Published var selectedMunicipality: String?
    
    // Edit/Delete related properties
    @Published var isEditing: Bool = false
    @Published var editingPost: Post?
    @Published var showDeleteConfirmation: Bool = false
    @Published var postToDelete: Post?
    @Published var isDeleting: Bool = false
    @Published var isUpdating: Bool = false
    
    private let postAPIService = PostAPIService()
    private let imageUploadService = ImageUploadService()
    
    // MARK: - Validation
    
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
    
    // Enhanced validation for content - requires text AND images
    func validateContent() -> Result<Void, PostError> {
        let hasText = !postContent.isEmpty
        let hasImages = !selectedImages.isEmpty
        
        
        if !hasText && !hasImages {
            return .failure(.noContent)
        }
        
        if hasText && postContent.count > 300 {
            return .failure(.contentOverLimit(currentCount: postContent.count, maxCount: 300))
        }
        return .success(())
    }
    
    // Enhanced validation for images - optional but if provided, must be valid
    func validateImages() -> Result<Void, PostError> {
        // Images are optional, so empty is allowed
        if selectedImages.isEmpty {
            return .success(())
        }
        
        if selectedImages.count > 5 {
            return .failure(.tooManyImages(currentCount: selectedImages.count, maxCount: 5))
        }
        
        // Validate each image
        for image in selectedImages {
            if image.size.width == 0 || image.size.height == 0 {
                return .failure(.invalidImageData)
            }
        }
        
        return .success(())
    }
    
    // Enhanced validation for tags - minimum 1 tag required
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
        
        // Validate content (text OR images)
        switch validateContent() {
        case .failure(let error):
            return .failure(error)
        case .success:
            break
        }
        
        // Validate images if provided
        switch validateImages() {
        case .failure(let error):
            return .failure(error)
        case .success:
            break
        }
        
        // Validate tags (minimum 1 required)
        switch validateTags() {
        case .failure(let error):
            return .failure(error)
        case .success:
            break
        }
        
        return .success(())
    }
    
    // Get current validation state for UI feedback
    func getValidationState() -> ValidationState {
        let contentValidation = validateContent()
        let imageValidation = validateImages()
        let tagValidation = validateTags()
        
        var errors: [PostError] = []
        
        if case .failure(let error) = contentValidation {
            errors.append(error)
        }
        
        if case .failure(let error) = imageValidation {
            errors.append(error)
        }
        
        if case .failure(let error) = tagValidation {
            errors.append(error)
        }
        
        // Add submission in progress error if applicable
        if isSubmitting {
            errors.append(.submissionInProgress)
        }
        
        return ValidationState(
            isValid: errors.isEmpty && !isSubmitting,
            errors: errors,
            canPost: canPost
        )
    }
    
    // Get detailed validation information for specific aspects
    func getContentValidationState() -> ContentValidationState {
        let hasText = !postContent.isEmpty
        let hasImages = !selectedImages.isEmpty
        let isOverLimit = postContent.count > 500
        
        if !hasText && !hasImages {
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
    
    // MARK: - Tag Management
    
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
    
    // MARK: - New Tag Management
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            // Prevent removing last tag - minimum 1 tag required
            if selectedTags.count > 1 {
                selectedTags.remove(tag)
            }
        } else {
            // Prevent selecting more than 5 tags
            if selectedTags.count < 5 {
                selectedTags.insert(tag)
            }
        }
    }
    
    func resetForm() {
        postContent = ""
        selectedImage = nil
        selectedImages = []
        selectedShop = nil
        imageURL = nil
        tags = []
        tagInput = ""
        selectedTags = ["熊本県全体"]
        errorMessage = nil
        showSuccessModal = false
        isEditing = false
        editingPost = nil
    }
    
    // MARK: - API Calls
    
    func fetchAllPosts() async {
        await performAsyncOperation {
            self.posts = try await self.postAPIService.fetchAllPosts()
        }
    }
    
    func fetchUserPosts(userId: Int) async {
        await performAsyncOperation {
            self.userPosts = try await self.postAPIService.fetchUserPosts(userId: userId)
        }
    }
    
    func postPost(userId: Int, content: String) async -> Bool {
        // Validate before submission
        switch validateForSubmission() {
        case .failure(let error):
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
            // Upload image if present
            var uploadedImageURL: String? = nil
            if let image = selectedImage {
                uploadedImageURL = try await uploadImage(image)
            }
            
            // Post post
            let newPost = try await postAPIService.createPost(
                userId: userId,
                content: content,
                imageUrl: uploadedImageURL,
                tags: Array(selectedTags)
            )
            
            // Success handling
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
    
    func createPostWithMultipleImages(userId: Int, content: String, shopId: Int?, images: [UIImage]) async -> Bool {
        // Validate before submission
        switch validateForSubmission() {
        case .failure(let error):
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
            // Upload multiple images
            var uploadedImageURLs: [String] = []
            for (index, image) in images.enumerated() {
                let imageURL = try await uploadImage(image)
                uploadedImageURLs.append(imageURL)
                print("✅ 画像 \(index + 1)/\(images.count) アップロード完了: \(imageURL)")
            }
            
            // Create post with multiple images
            let newPost = try await postAPIService.createPostWithMultipleImages(
                userId: userId,
                content: content,
                shopId: shopId,
                imageUrls: uploadedImageURLs,
                tags: Array(selectedTags)
            )
            
            // Success handling
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
    
    // MARK: - Edit/Delete Methods
    
    func startEditing(_ post: Post) {
        editingPost = post
        postContent = post.content
        selectedShop = post.shop
        tags = post.tags ?? []
        // Convert existing tags to selectedTags Set, or use default if empty
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
        
        // Validate before submission
        switch validateForSubmission() {
        case .failure(let error):
            await handleValidationError(error)
            return false
        case .success:
            break
        }
        
        isUpdating = true
        isLoading = true
        errorMessage = nil
        
        // Store original post for rollback
        let originalPost = post
        let originalIndex = posts.firstIndex { $0.id == post.id }
        let originalUserIndex = userPosts.firstIndex { $0.id == post.id }
        
        // Optimistic update
        var updatedPost = post
        updatedPost.content = postContent
        updatedPost.shopId = selectedShop?.id
        updatedPost.shop = selectedShop
        updatedPost.tags = selectedTags.isEmpty ? nil : Array(selectedTags)
        updatedPost.updatedAt = Date()
        
        // Update UI optimistically
        if let index = originalIndex {
            posts[index] = updatedPost
        }
        if let index = originalUserIndex {
            userPosts[index] = updatedPost
        }
        
        do {
            let serverPost = try await postAPIService.updatePost(
                postId: post.id,
                content: postContent,
                shopId: selectedShop?.id,
                tags: Array(selectedTags)
            )
            
            // Update with server response
            if let index = originalIndex {
                posts[index] = serverPost
            }
            if let index = originalUserIndex {
                userPosts[index] = serverPost
            }
            
            // Success handling
            await handleSuccessfulUpdate()
            return true
            
        } catch let error as PostAPIError {
            // Rollback optimistic update
            if let index = originalIndex {
                posts[index] = originalPost
            }
            if let index = originalUserIndex {
                userPosts[index] = originalPost
            }
            
            await handlePostAPIError(error)
        } catch {
            // Rollback optimistic update
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
        
        // Store original data for rollback
        let originalIndex = posts.firstIndex { $0.id == post.id }
        let originalUserIndex = userPosts.firstIndex { $0.id == post.id }
        
        // Optimistic update - remove from UI
        posts.removeAll { $0.id == post.id }
        userPosts.removeAll { $0.id == post.id }
        
        do {
            try await postAPIService.deletePost(postId: post.id)
            
            // Success handling
            await handleSuccessfulDeletion()
            return true
            
        } catch let error as PostAPIError {
            // Rollback optimistic update
            if let index = originalIndex {
                posts.insert(post, at: index)
            }
            if let index = originalUserIndex {
                userPosts.insert(post, at: index)
            }
            
            await handlePostAPIError(error)
        } catch {
            // Rollback optimistic update
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
            let post = try await postAPIService.fetchPost(postId: postId)
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
    
    // MARK: - Helper Methods
    
    func isPostOwner(_ post: Post) -> Bool {
        guard let currentUser = AuthService.shared.currentUser else { return false }
        return post.userId == currentUser.id
    }
    
    private func handleSuccessfulUpdate() async {
        // Reset form using new resetForm method
        resetForm()
        
        isLoading = false
        isUpdating = false
        
        // Show success message briefly
        showSuccessModal = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showSuccessModal = false
        }
    }
    
    private func handleSuccessfulDeletion() async {
        // Reset deletion state
        postToDelete = nil
        showDeleteConfirmation = false
        
        isLoading = false
        isDeleting = false
        
        // Show success message briefly
        showSuccessModal = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showSuccessModal = false
        }
    }
    
    // MARK: - Private Methods
    
    private func uploadImage(_ image: UIImage) async throws -> String {
        do {
            let imageURL = try await imageUploadService.uploadImage(image)
            print("✅ 画像アップロード成功: \(imageURL)")
            return imageURL
        } catch let error as ImageUploadError {
            print("❌ 画像アップロード失敗: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ 画像アップロード失敗: \(error.localizedDescription)")
            throw ImageUploadError.uploadFailed(reason: error.localizedDescription)
        }
    }
    
    private func handleSuccessfulSubmission(_ newPost: Post) async {
        posts.insert(newPost, at: 0)
        userPosts.insert(newPost, at: 0)
        
        // Show success modal first
        showSuccessModal = true
        isLoading = false
        isSubmitting = false
        
        // Reset form after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.resetForm()
        }
        
        // Auto-hide modal after showing success message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showSuccessModal = false
        }
    }
    
    private func performAsyncOperation<T>(_ operation: @escaping () async throws -> T) async {
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
    
    // MARK: - Error Handling
    
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
        case .networkError(let err):
            apiError = .networkError(err)
        case .invalidResponse:
            apiError = .invalidResponse
        case .decodingError(let err):
            if let decodingError = err as? DecodingError {
                apiError = .decodingError(decodingError)
            } else {
                let context = DecodingError.Context(codingPath: [], debugDescription: err.localizedDescription)
                apiError = .decodingError(.dataCorrupted(context))
            }
        case .apiError(let statusCode, let message):
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
        case .serverError(let message):
            apiError = .serverError(message: message)
        case .unknownError(let err):
            apiError = .unknownError(err)
        case .timeout:
            apiError = .timeout
        case .engagementDataError(let message):
            // Handle engagement-specific errors gracefully
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
        
        // Log detailed error information
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
        
        // Log detailed error information
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
        
        // Log detailed error information
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

// MARK: - Tab Management

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
            // TODO: Implement municipality-specific API call
            self.posts = try await self.postAPIService.fetchAllPosts()
        }
    }
    
    private func fetchFollowingPosts() async {
        await performAsyncOperation {
            // TODO: Implement following-specific API call
            self.posts = try await self.postAPIService.fetchAllPosts()
        }
    }
}
