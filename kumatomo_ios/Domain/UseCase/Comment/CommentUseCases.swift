import Foundation

protocol FetchCommentsUseCase { func execute(postId: Int) async throws -> [Comment] }
protocol CreateCommentUseCase { func execute(postId: Int, content: String, imageData: Data?) async throws -> Comment }

final class FetchCommentsUseCaseImpl: FetchCommentsUseCase {
    private let repository: CommentRepository
    init(repository: CommentRepository) { self.repository = repository }
    func execute(postId: Int) async throws -> [Comment] { try await repository.fetchComments(postId: postId) }
}

final class CreateCommentUseCaseImpl: CreateCommentUseCase {
    private let repository: CommentRepository
    init(repository: CommentRepository) { self.repository = repository }
    func execute(postId: Int, content: String, imageData: Data?) async throws -> Comment {
        try await repository.createComment(postId: postId, content: content, imageData: imageData)
    }
}

