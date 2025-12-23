import Foundation
import UIKit

// MARK: - CommentAPIService

/// APIClient経由のコメントAPIサービス
class CommentAPIService {
    static let shared = CommentAPIService()

    private let client = APIClient.shared
    private let imageUploadService = ImageUploadService.shared
    private let logger = AppLogger.network

    private init() {}

    // MARK: - Fetch Comments

    func fetchComments(postId: Int) async throws -> [Comment] {
        do {
            let comments: [Comment] = try await client.get(CommentEndpoint.fetchComments(postId: postId))
            logger.info("コメント取得成功: \(comments.count)件")
            return comments
        } catch let apiError as APIError {
            throw handleAPIError(apiError)
        } catch {
            throw CommentError.networkError(error)
        }
    }

    // MARK: - Create Comment

    func createComment(postId: Int, content: String, image: UIImage? = nil) async throws -> Comment {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedContent.isEmpty || image != nil else {
            throw CommentError.emptyContent
        }

        let maxLength = 500
        guard trimmedContent.count <= maxLength else {
            throw CommentError.contentTooLong(currentCount: trimmedContent.count, maxCount: maxLength)
        }

        var imageUrl: String?
        if let image {
            do {
                imageUrl = try await imageUploadService.uploadImage(image)
                logger.info("コメント画像アップロード成功: \(imageUrl ?? "")")
            } catch {
                logger.logError(error, context: "CommentImageUpload")
                throw CommentError.imageUploadFailed(error)
            }
        }

        do {
            let comment: Comment = try await client.post(
                CommentEndpoint.createComment(postId: postId, content: trimmedContent, imageUrl: imageUrl)
            )
            logger.info("コメント作成成功: ID \(comment.id)")
            return comment
        } catch let apiError as APIError {
            throw handleAPIError(apiError)
        } catch {
            throw CommentError.networkError(error)
        }
    }

    // MARK: - Delete Comment

    func deleteComment(commentId: Int) async throws {
        do {
            try await client.delete(CommentEndpoint.deleteComment(commentId: commentId))
            logger.info("コメント削除成功: ID \(commentId)")
        } catch let apiError as APIError {
            throw handleAPIError(apiError)
        } catch {
            throw CommentError.networkError(error)
        }
    }

    // MARK: - Convenience Methods

    func createTextComment(postId: Int, content: String) async throws -> Comment {
        try await createComment(postId: postId, content: content, image: nil)
    }

    func createImageComment(postId: Int, image: UIImage) async throws -> Comment {
        try await createComment(postId: postId, content: " ", image: image)
    }

    func validateCommentContent(_ content: String, maxLength: Int = 500) throws {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedContent.isEmpty else {
            throw CommentError.emptyContent
        }

        guard trimmedContent.count <= maxLength else {
            throw CommentError.contentTooLong(currentCount: trimmedContent.count, maxCount: maxLength)
        }
    }

    // MARK: - Private Helpers

    private func handleAPIError(_ error: APIError) -> CommentError {
        switch error {
        case .unauthorized:
            return .unauthorized
        case .notFound:
            return .postNotFound
        case let .apiError(statusCode, message):
            if statusCode == 403 {
                return .apiError(403, "このコメントを削除する権限がありません")
            }
            return .apiError(statusCode, message)
        case let .networkError(underlyingError):
            if let urlError = underlyingError as? URLError, urlError.code == .timedOut {
                return .timeout
            }
            return .networkError(underlyingError)
        case let .decodingError(decodingError):
            return .decodingError(decodingError)
        default:
            return .unknownError(error)
        }
    }
}
