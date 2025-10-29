import Foundation
import SwiftUI
import UIKit
import Resolver

@MainActor
class CommentViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var commentText: String = ""
    @Published var selectedImage: UIImage?
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    @Published var showImagePicker: Bool = false
    
    // Validation states
    @Published var isValidating: Bool = false
    @Published var validationError: String?
    
    // MARK: - Constants
    
    private let maxCharacterCount = 500
    private let maxImageSizeBytes = 10 * 1024 * 1024 // 10MB
    private let maxImageDimension: CGFloat = 2048
    
    // MARK: - Services
    
    @Injected var createCommentUseCase: CreateCommentUseCase
    
    // MARK: - Computed Properties
    
    /// Check if the comment can be submitted
    var canSubmit: Bool {
        let hasValidText = !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = selectedImage != nil
        let isNotSubmitting = !isSubmitting
        let hasNoValidationError = validationError == nil
        let hasContent = hasValidText || hasImage
        
        return hasContent && isNotSubmitting && hasNoValidationError
    }
    
    /// Get current character count
    var characterCount: Int {
        return commentText.count
    }
    
    /// Check if character count is over limit
    var isOverCharacterLimit: Bool {
        return commentText.count > maxCharacterCount
    }
    
    /// Get remaining character count
    var remainingCharacterCount: Int {
        return maxCharacterCount - commentText.count
    }
    
    /// Get character count display text
    var characterCountText: String {
        let remaining = remainingCharacterCount
        if remaining < 0 {
            return "\(remaining)"
        } else if remaining <= 50 {
            return "\(remaining)"
        } else {
            return ""
        }
    }
    
    /// Get character count color
    var characterCountColor: Color {
        let remaining = remainingCharacterCount
        if remaining < 0 {
            return .red
        } else if remaining <= 20 {
            return .orange
        } else if remaining <= 50 {
            return .yellow
        } else {
            return .secondary
        }
    }
    
    /// Check if form has any content
    var hasContent: Bool {
        let hasText = !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = selectedImage != nil
        return hasText || hasImage
    }
    
    // MARK: - Validation Methods
    
    /// Validate comment content in real-time
    func validateContent() {
        isValidating = true
        validationError = nil
        
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if completely empty (only show error if user has started typing)
        if trimmedText.isEmpty && selectedImage == nil && !commentText.isEmpty {
            validationError = "コメント内容を入力するか、画像を選択してください"
            isValidating = false
            return
        }
        
        // Check character limit
        if trimmedText.count > maxCharacterCount {
            validationError = "コメントが長すぎます（\(trimmedText.count)/\(maxCharacterCount)文字）"
            isValidating = false
            return
        }
        
        // Validate image if present
        if let image = selectedImage {
            let validationResult = validateImage(image)
            if !validationResult.isValid {
                validationError = validationResult.errorMessage
                isValidating = false
                return
            }
        }
        
        isValidating = false
    }
    
    /// Validate image size and dimensions
    /// - Parameter image: The image to validate
    /// - Returns: Validation result with error message if invalid
    private func validateImage(_ image: UIImage) -> (isValid: Bool, errorMessage: String?) {
        // Check image data size
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return (false, "画像の処理に失敗しました")
        }
        
        if imageData.count > maxImageSizeBytes {
            let sizeMB = Double(imageData.count) / (1024 * 1024)
            let maxSizeMB = Double(maxImageSizeBytes) / (1024 * 1024)
            return (false, "画像サイズが大きすぎます（\(String(format: "%.1f", sizeMB))MB/\(String(format: "%.0f", maxSizeMB))MB）")
        }
        
        // Check image dimensions
        let size = image.size
        if size.width > maxImageDimension || size.height > maxImageDimension {
            return (false, "画像の解像度が高すぎます（最大\(Int(maxImageDimension))px）")
        }
        
        return (true, nil)
    }
    
    /// Validate before submission
    /// - Returns: Validation result with error message if invalid
    func validateForSubmission() -> (isValid: Bool, errorMessage: String?) {
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if completely empty
        if trimmedText.isEmpty && selectedImage == nil {
            return (false, "コメント内容を入力するか、画像を選択してください")
        }
        
        // Check character limit
        if trimmedText.count > maxCharacterCount {
            return (false, "コメントが長すぎます（\(trimmedText.count)/\(maxCharacterCount)文字）")
        }
        
        // Validate image if present
        if let image = selectedImage {
            return validateImage(image)
        }
        
        return (true, nil)
    }
    
    // MARK: - Comment Submission
    
    /// Submit comment to the specified post
    /// - Parameter postId: The ID of the post to comment on
    /// - Returns: True if successful, false otherwise
    func submitComment(postId: Int) async -> Bool {
        // Prevent multiple simultaneous submissions
        guard !isSubmitting else { return false }
        
        // Validate before submission
        let validation = validateForSubmission()
        guard validation.isValid else {
            await showError(validation.errorMessage ?? "入力内容を確認してください")
            return false
        }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
            let comment = try await createCommentUseCase.execute(postId: postId, content: trimmedText, imageData: imageData)
            
            // Clear form on success
            clearForm()
            
            // Show success message
            await showSuccess("コメントを投稿しました")
            
            print("✅ CommentViewModel: コメント投稿成功 - ID: \(comment.id)")
            
            isSubmitting = false
            return true
            
        } catch let error as CommentError {
            await handleCommentError(error)
            isSubmitting = false
            return false
        } catch {
            await handleGenericError(error)
            isSubmitting = false
            return false
        }
    }
    
    // MARK: - Form Management
    
    /// Clear the comment form
    func clearForm() {
        commentText = ""
        selectedImage = nil
        errorMessage = nil
        validationError = nil
        showSuccessMessage = false
        successMessage = ""
    }
    
    /// Set comment text and validate
    /// - Parameter text: The text to set
    func setCommentText(_ text: String) {
        commentText = text
        validateContent()
    }
    
    /// Set selected image and validate
    /// - Parameter image: The image to set
    func setSelectedImage(_ image: UIImage?) {
        selectedImage = image
        validateContent()
    }
    
    /// Remove selected image
    func removeSelectedImage() {
        selectedImage = nil
        validateContent()
    }
    
    /// Process image selection with validation and resizing
    /// - Parameter image: The selected image
    func processSelectedImage(_ image: UIImage) {
        // Resize image if needed
        let processedImage = resizeImageIfNeeded(image)
        setSelectedImage(processedImage)
    }
    
    /// Resize image if it exceeds maximum dimensions
    /// - Parameter image: The image to resize
    /// - Returns: Resized image or original if no resizing needed
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let size = image.size
        
        // Check if resizing is needed
        guard size.width > maxImageDimension || size.height > maxImageDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxImageDimension, height: maxImageDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxImageDimension * aspectRatio, height: maxImageDimension)
        }
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        print("📷 CommentViewModel: 画像リサイズ - 元: \(size) → 新: \(newSize)")
        
        return resizedImage ?? image
    }
    
    // MARK: - Character Count Management
    
    /// Handle text change with character limit enforcement
    /// - Parameter newText: The new text value
    func handleTextChange(_ newText: String) {
        // Allow typing but show validation error if over limit
        commentText = newText
        validateContent()
    }
    
    /// Get formatted character count for display
    /// - Returns: Formatted character count string
    func getFormattedCharacterCount() -> String {
        let current = characterCount
        let max = maxCharacterCount
        
        if current > max {
            return "\(current)/\(max)"
        } else if current > max - 50 {
            return "\(current)/\(max)"
        } else {
            return ""
        }
    }
    
    // MARK: - Message Handling
    
    /// Show success message
    /// - Parameter message: The success message to show
    private func showSuccess(_ message: String) async {
        successMessage = message
        showSuccessMessage = true
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showSuccessMessage = false
        }
    }
    
    /// Show error message
    /// - Parameter message: The error message to show
    private func showError(_ message: String) async {
        errorMessage = message
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.errorMessage == message {
                self.errorMessage = nil
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleCommentError(_ error: CommentError) async {
        let message: String
        
        switch error {
        case .emptyContent:
            message = "コメント内容を入力してください"
        case .contentTooLong(let current, let max):
            message = "コメントが長すぎます（\(current)/\(max)文字）"
        case .imageUploadFailed(let uploadError):
            message = "画像のアップロードに失敗しました: \(uploadError.localizedDescription)"
        case .networkError(let networkError):
            message = "ネットワークエラーが発生しました: \(networkError.localizedDescription)"
        case .unauthorized:
            message = "認証が必要です。ログインしてください"
        case .postNotFound:
            message = "投稿が見つかりません"
        case .commentNotFound:
            message = "コメントが見つかりません"
        case .invalidURL:
            message = "無効なURLです"
        case .invalidResponse:
            message = "無効なレスポンスです"
        case .decodingError(let decodingError):
            message = "データの読み込みに失敗しました: \(decodingError.localizedDescription)"
        case .apiError(let code, let apiMessage):
            switch code {
            case 401:
                message = "認証が必要です"
            case 403:
                message = "アクセス権限がありません"
            case 404:
                message = "投稿が見つかりません"
            case 422:
                message = "入力内容に問題があります: \(apiMessage)"
            case 429:
                message = "リクエストが多すぎます。しばらく待ってからお試しください"
            default:
                message = "APIエラー（\(code)）: \(apiMessage)"
            }
        case .serverError(let serverMessage):
            message = "サーバーエラー: \(serverMessage)"
        case .timeout:
            message = "リクエストがタイムアウトしました"
        case .unknownError(let unknownError):
            message = "不明なエラー: \(unknownError.localizedDescription)"
        }
        
        await showError(message)
        print("🚨 CommentViewModel: CommentError - \(message)")
    }
    
    private func handleGenericError(_ error: Error) async {
        let message = "予期しないエラーが発生しました: \(error.localizedDescription)"
        await showError(message)
        print("🚨 CommentViewModel: GenericError - \(message)")
    }
    
    // MARK: - Utility Methods
    
    /// Reset all state to initial values
    func reset() {
        commentText = ""
        selectedImage = nil
        isSubmitting = false
        errorMessage = nil
        showSuccessMessage = false
        successMessage = ""
        showImagePicker = false
        isValidating = false
        validationError = nil
    }
    
    /// Get current form state summary
    var formStateSummary: String {
        var components: [String] = []
        
        if !commentText.isEmpty {
            components.append("テキスト: \(commentText.count)文字")
        }
        
        if selectedImage != nil {
            components.append("画像: あり")
        }
        
        if isSubmitting {
            components.append("送信中")
        }
        
        if let error = validationError {
            components.append("エラー: \(error)")
        }
        
        return components.isEmpty ? "空のフォーム" : components.joined(separator: ", ")
    }
}

// MARK: - Extensions

extension CommentViewModel {
    /// Get validation status for UI feedback
    var validationStatus: ValidationStatus {
        if isValidating {
            return .validating
        } else if let _ = validationError {
            return .invalid
        } else if hasContent {
            return .valid
        } else {
            return .empty
        }
    }
    
    enum ValidationStatus {
        case empty
        case validating
        case valid
        case invalid
    }
}

// MARK: - Preview Support

#if DEBUG
extension CommentViewModel {
    /// Create a mock instance for previews
    static func mock() -> CommentViewModel {
        let viewModel = CommentViewModel()
        viewModel.commentText = "これはサンプルコメントです"
        return viewModel
    }
    
    /// Create a mock instance with validation error
    static func mockWithError() -> CommentViewModel {
        let viewModel = CommentViewModel()
        viewModel.commentText = String(repeating: "あ", count: 600) // Over limit
        viewModel.validateContent()
        return viewModel
    }
    
    /// Create a mock instance that's submitting
    static func mockSubmitting() -> CommentViewModel {
        let viewModel = CommentViewModel()
        viewModel.commentText = "送信中のコメント"
        viewModel.isSubmitting = true
        return viewModel
    }
}
#endif
