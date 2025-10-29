import Foundation

// Domain layer protocol for comment operations (UIKit-independent)
protocol CommentRepository {
    func fetchComments(postId: Int) async throws -> [Comment]
    func createComment(postId: Int, content: String, imageData: Data?) async throws -> Comment
}
