import Foundation
import UIKit

final class CommentRepositoryImpl: CommentRepository {
    private let service: CommentAPIService

    init(service: CommentAPIService = .shared) {
        self.service = service
    }

    func fetchComments(postId: Int) async throws -> [Comment] {
        try await service.fetchComments(postId: postId)
    }

    func createComment(postId: Int, content: String, imageData: Data?) async throws -> Comment {
        var uiImage: UIImage?
        if let data = imageData { uiImage = UIImage(data: data) }
        return try await service.createComment(postId: postId, content: content, image: uiImage)
    }
}
