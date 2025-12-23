import Foundation

// コメントAPI用エンドポイント定義
enum CommentEndpoint: APIEndpoint {
    case fetchComments(postId: Int)
    case createComment(postId: Int, content: String, imageUrl: String?)
    case deleteComment(commentId: Int)

    var path: String {
        switch self {
        case let .fetchComments(postId):
            return "/posts/\(postId)/comments"
        case let .createComment(postId, _, _):
            return "/posts/\(postId)/comments"
        case let .deleteComment(commentId):
            return "/comments/\(commentId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchComments:
            return .get
        case .createComment:
            return .post
        case .deleteComment:
            return .delete
        }
    }

    var body: [String: Any]? {
        switch self {
        case let .createComment(_, content, imageUrl):
            var body: [String: Any] = ["content": content]
            if let imageUrl {
                body["image_url"] = imageUrl
            }
            return body
        default:
            return nil
        }
    }
}
