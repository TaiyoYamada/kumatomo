import Foundation
import SwiftUI
import UIKit
import Factory
import Observation

// MARK: - CommentViewModel

@MainActor
@Observable
class CommentViewModel {

    var commentText: String = ""
    var selectedImage: UIImage?
    var isSubmitting: Bool = false
    var errorMessage: String?
    var showSuccessMessage: Bool = false
    var successMessage: String = ""
    var showImagePicker: Bool = false

    var isValidating: Bool = false
    var validationError: String?

    private let maxCharacterCount = 500
    private let maxImageSizeBytes = 10 * 1_024 * 1_024
    private let maxImageDimension: CGFloat = 2_048

    @ObservationIgnored @Injected(\.createCommentUseCase) var createCommentUseCase

    init() {}

    var canSubmit: Bool {
        let hasValidText = !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = selectedImage != nil
        let isNotSubmitting = !isSubmitting
        let hasNoValidationError = validationError == nil
        let hasContent = hasValidText || hasImage

        return hasContent && isNotSubmitting && hasNoValidationError
    }

    var characterCount: Int {
        return commentText.count
    }

    var isOverCharacterLimit: Bool {
        return commentText.count > maxCharacterCount
    }

    var remainingCharacterCount: Int {
        return maxCharacterCount - commentText.count
    }

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

    var hasContent: Bool {
        let hasText = !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = selectedImage != nil
        return hasText || hasImage
    }

    func validateContent() {
        isValidating = true
        validationError = nil

        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText.isEmpty, selectedImage == nil, !commentText.isEmpty {
            validationError = "コメント内容を入力するか、画像を選択してください"
            isValidating = false
            return
        }

        if trimmedText.count > maxCharacterCount {
            validationError = "コメントが長すぎます（\(trimmedText.count)/\(maxCharacterCount)文字）"
            isValidating = false
            return
        }

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

    private func validateImage(_ image: UIImage) -> (isValid: Bool, errorMessage: String?) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return (false, "画像の処理に失敗しました")
        }

        if imageData.count > maxImageSizeBytes {
            let sizeMB = Double(imageData.count) / (1_024 * 1_024)
            let maxSizeMB = Double(maxImageSizeBytes) / (1_024 * 1_024)
            return (false, "画像サイズが大きすぎます（\(String(format: "%.1f", sizeMB))MB/\(String(format: "%.0f", maxSizeMB))MB）")
        }

        let size = image.size
        if size.width > maxImageDimension || size.height > maxImageDimension {
            return (false, "画像の解像度が高すぎます（最大\(Int(maxImageDimension))px）")
        }

        return (true, nil)
    }

    func validateForSubmission() -> (isValid: Bool, errorMessage: String?) {
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText.isEmpty, selectedImage == nil {
            return (false, "コメント内容を入力するか、画像を選択してください")
        }

        if trimmedText.count > maxCharacterCount {
            return (false, "コメントが長すぎます（\(trimmedText.count)/\(maxCharacterCount)文字）")
        }

        if let image = selectedImage {
            return validateImage(image)
        }

        return (true, nil)
    }

    func submitComment(postId: Int) async -> Bool {
        guard !isSubmitting else { return false }

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
            let comment = try await createCommentUseCase.execute(
                postId: postId,
                content: trimmedText,
                imageData: imageData
            )

            clearForm()

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

    func clearForm() {
        commentText = ""
        selectedImage = nil
        errorMessage = nil
        validationError = nil
        showSuccessMessage = false
        successMessage = ""
    }

    func setCommentText(_ text: String) {
        commentText = text
        validateContent()
    }

    func setSelectedImage(_ image: UIImage?) {
        selectedImage = image
        validateContent()
    }

    func removeSelectedImage() {
        selectedImage = nil
        validateContent()
    }

    func processSelectedImage(_ image: UIImage) {
        let processedImage = resizeImageIfNeeded(image)
        setSelectedImage(processedImage)
    }

    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let size = image.size

        guard size.width > maxImageDimension || size.height > maxImageDimension else {
            return image
        }

        let aspectRatio = size.width / size.height
        let newSize = if size.width > size.height {
            CGSize(width: maxImageDimension, height: maxImageDimension / aspectRatio)
        } else {
            CGSize(width: maxImageDimension * aspectRatio, height: maxImageDimension)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        print("📷 CommentViewModel: 画像リサイズ - 元: \(size) → 新: \(newSize)")

        return resizedImage ?? image
    }

    func handleTextChange(_ newText: String) {
        commentText = newText
        validateContent()
    }

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

    private func showSuccess(_ message: String) async {
        successMessage = message
        showSuccessMessage = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showSuccessMessage = false
        }
    }

    private func showError(_ message: String) async {
        errorMessage = message

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.errorMessage == message {
                self.errorMessage = nil
            }
        }
    }

    private func handleCommentError(_ error: CommentError) async {
        let message = switch error {
        case .emptyContent:
            "コメント内容を入力してください"
        case let .contentTooLong(current, max):
            "コメントが長すぎます（\(current)/\(max)文字）"
        case let .imageUploadFailed(uploadError):
            "画像のアップロードに失敗しました: \(uploadError.localizedDescription)"
        case let .networkError(networkError):
            "ネットワークエラーが発生しました: \(networkError.localizedDescription)"
        case .unauthorized:
            "認証が必要です。ログインしてください"
        case .postNotFound:
            "投稿が見つかりません"
        case .commentNotFound:
            "コメントが見つかりません"
        case .invalidURL:
            "無効なURLです"
        case .invalidResponse:
            "無効なレスポンスです"
        case let .decodingError(decodingError):
            "データの読み込みに失敗しました: \(decodingError.localizedDescription)"
        case let .apiError(code, apiMessage):
            switch code {
            case 401:
                "認証が必要です"
            case 403:
                "アクセス権限がありません"
            case 404:
                "投稿が見つかりません"
            case 422:
                "入力内容に問題があります: \(apiMessage)"
            case 429:
                "リクエストが多すぎます。しばらく待ってからお試しください"
            default:
                "APIエラー（\(code)）: \(apiMessage)"
            }
        case let .serverError(serverMessage):
            "サーバーエラー: \(serverMessage)"
        case .timeout:
            "リクエストがタイムアウトしました"
        case let .unknownError(unknownError):
            "不明なエラー: \(unknownError.localizedDescription)"
        }

        await showError(message)
        print("🚨 CommentViewModel: CommentError - \(message)")
    }

    private func handleGenericError(_ error: Error) async {
        let message = "予期しないエラーが発生しました: \(error.localizedDescription)"
        await showError(message)
        print("🚨 CommentViewModel: GenericError - \(message)")
    }

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

extension CommentViewModel {
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

#if DEBUG
extension CommentViewModel {
    static func mock() -> CommentViewModel {
        let viewModel = CommentViewModel()
        viewModel.commentText = "これはサンプルコメントです"
        return viewModel
    }

    static func mockWithError() -> CommentViewModel {
        let viewModel = CommentViewModel()
        viewModel.commentText = String(repeating: "あ", count: 600)
        viewModel.validateContent()
        return viewModel
    }

    static func mockSubmitting() -> CommentViewModel {
        let viewModel = CommentViewModel()
        viewModel.commentText = "送信中のコメント"
        viewModel.isSubmitting = true
        return viewModel
    }
}
#endif
