import Foundation
import Mockable

@Mockable
protocol CommentRepository {
    func fetchComments(postId: Int) async throws -> [Comment]
    func createComment(postId: Int, content: String, imageData: Data?) async throws -> Comment
}
