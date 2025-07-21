import Foundation
import SwiftUI
import Combine

@MainActor
class PostViewModel: ObservableObject {
    @Published var postContent: String = ""
    @Published var postTitle: String = ""
    @Published var selectedImage: UIImage?
    @Published var imageURL: String?
    @Published var tags: [String] = []
    @Published var tagInput: String = ""
    
    @Published var stories: [Post] = []
    @Published var userStories: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessModal: Bool = false
    @Published var isSubmitting: Bool = false
    
    private let postAPIService = PostAPIService()
    private let imageUploadService = ImageUploadService()
    
    // MARK: - Validation
    
    func validateContent() -> Result<Void, PostValidationError> {
        if postContent.isEmpty {
            return .failure(.contentEmpty)
        }
        
        if postContent.count > 100 {
            return .failure(.contentTooLong(currentCount: postContent.count, maxCount: 100))
        }
        
        return .success(())
    }
    
    func validateTitle() -> Result<Void, PostValidationError> {
        if postTitle.isEmpty {
            return .failure(.titleEmpty)
        }
        
        if postTitle.count > 50 {
            return .failure(.titleTooLong(currentCount: postTitle.count, maxCount: 50))
        }
        
        return .success(())
    }
    
    func validateForSubmission() -> Result<Void, PostError> {
        if isSubmitting {
            return .failure(.submissionInProgress)
        }
        
        switch validateContent() {
        case .failure(let error):
            return .failure(PostError.contentEmpty) // Convert validation error to post error
        case .success:
            break
        }
        
        switch validateTitle() {
        case .failure(let error):
            return .failure(PostError.titleEmpty) // Convert validation error to post error
        case .success:
            break
        }
        
        if let image = selectedImage {
            // Basic image validation
            if image.size.width == 0 || image.size.height == 0 {
                return .failure(.invalidImageData)
            }
        }
        
        return .success(())
    }
    
    // MARK: - Tag Management
    
    func addTag() -> Result<Void, PostValidationError> {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTag.isEmpty {
            return .failure(.tagEmpty)
        }
        
        if tags.contains(trimmedTag) {
            return .failure(.duplicateTag(tagName: trimmedTag))
        }
        
        if tags.count >= 5 {
            return .failure(.tooManyTags(currentCount: tags.count, maxCount: 5))
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
    
    // MARK: - API Calls
    
    func fetchAllStories() async {
        await performAsyncOperation {
            self.stories = try await self.postAPIService.fetchAllStories()
        }
    }
    
    func fetchUserStories(userId: Int) async {
        await performAsyncOperation {
            self.userStories = try await self.postAPIService.fetchUserStories(userId: userId)
        }
    }
    
    func postPost(userId: Int, title: String, content: String) async -> Bool {
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
                title: title,
                content: content,
                imageUrl: uploadedImageURL,
                tags: tags
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
        stories.insert(newPost, at: 0)
        userStories.insert(newPost, at: 0)
        
        // Reset form
        postContent = ""
        postTitle = ""
        selectedImage = nil
        imageURL = nil
        tags = []
        tagInput = ""
        
        // Show success modal
        showSuccessModal = true
        isLoading = false
        isSubmitting = false
        
        // Auto-hide modal after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
    
    private func handleValidationError(_ error: PostValidationError) async {
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
