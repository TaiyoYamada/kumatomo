import Foundation
import UIKit

class CommentAPIService {
    static let shared = CommentAPIService()

    private let baseURL = APIConfig.shared.baseURLString
    private let imageUploadService = ImageUploadService.shared

    private init() {}

    private func getAuthToken() -> String {
        return AuthTokenManager.shared.token ?? ""
    }

    private func createAuthorizedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func logRequest(_ request: URLRequest, context: String) {
        print("💬 [\(context)] リクエスト: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        print("💬 [\(context)] ヘッダー: \(request.allHTTPHeaderFields ?? [:])")

        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("💬 [\(context)] ボディ: \(bodyString)")
        }
    }

    private func logResponse(_ data: Data, response: HTTPURLResponse, context: String) {
        print("💬 [\(context)] ステータスコード: \(response.statusCode)")

        if let jsonString = String(data: data, encoding: .utf8) {
            print("💬 [\(context)] レスポンス: \(jsonString)")
        }
    }

    func fetchComments(postId: Int) async throws -> [Comment] {
        let endpoint = "\(baseURL)/posts/\(postId)/comments"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw CommentError.invalidURL
        }

        let request = createAuthorizedRequest(url: url)
        logRequest(request, context: "fetchComments")

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CommentError.invalidResponse
            }

            logResponse(data, response: httpResponse, context: "fetchComments")

            switch httpResponse.statusCode {
            case 200:
                let decoder = APIHelper.makeDecoder()
                do {
                    let comments = try decoder.decode([Comment].self, from: data)
                    print("✅ コメント取得成功: \(comments.count)件")
                    return comments
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw CommentError.decodingError(error)
                }

            case 401:
                throw CommentError.unauthorized

            case 404:
                throw CommentError.postNotFound

            case 408:
                throw CommentError.timeout

            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw CommentError.apiError(httpResponse.statusCode, errorMessage)
            }

        } catch let error as CommentError {
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw CommentError.networkError(error)
        }
    }

    func createComment(postId: Int, content: String, image: UIImage? = nil) async throws -> Comment {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedContent.isEmpty || image != nil else {
            throw CommentError.emptyContent
        }

        let maxLength = 500
        guard trimmedContent.count <= maxLength else {
            throw CommentError.contentTooLong(currentCount: trimmedContent.count, maxCount: maxLength)
        }

        var imageUrl: String? = nil
        if let image {
            do {
                imageUrl = try await imageUploadService.uploadImage(image)
                print("✅ コメント画像アップロード成功: \(imageUrl ?? "")")
            } catch {
                print("🚨 コメント画像アップロード失敗: \(error)")
                throw CommentError.imageUploadFailed(error)
            }
        }

        let endpoint = "\(baseURL)/posts/\(postId)/comments"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw CommentError.invalidURL
        }

        var request = createAuthorizedRequest(url: url, method: "POST")

        var body: [String: Any] = [
            "content": trimmedContent,
        ]

        if let imageUrl {
            body["image_url"] = imageUrl
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw CommentError.unknownError(error)
        }

        logRequest(request, context: "createComment")

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CommentError.invalidResponse
            }

            logResponse(data, response: httpResponse, context: "createComment")

            switch httpResponse.statusCode {
            case 200, 201:
                let decoder = APIHelper.makeDecoder()
                do {
                    let comment = try decoder.decode(Comment.self, from: data)
                    print("✅ コメント作成成功: ID \(comment.id)")
                    return comment
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw CommentError.decodingError(error)
                }

            case 401:
                throw CommentError.unauthorized

            case 404:
                throw CommentError.postNotFound

            case 408:
                throw CommentError.timeout

            case 422:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let message = (json["message"] as? String) ?? "バリデーションエラー"
                    if let errors = json["errors"] as? [String: [String]] {
                        let detail = errors.values.flatMap { $0 }.joined(separator: "\n")
                        throw CommentError.apiError(422, message + (detail.isEmpty ? "" : "\n" + detail))
                    }
                    throw CommentError.apiError(422, message)
                }
                let errorMessage = String(data: data, encoding: .utf8) ?? "Validation error"
                throw CommentError.apiError(422, errorMessage)

            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw CommentError.apiError(httpResponse.statusCode, errorMessage)
            }

        } catch let error as CommentError {
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw CommentError.networkError(error)
        }
    }

    func deleteComment(commentId: Int) async throws {
        let endpoint = "\(baseURL)/comments/\(commentId)"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw CommentError.invalidURL
        }

        let request = createAuthorizedRequest(url: url, method: "DELETE")
        logRequest(request, context: "deleteComment")

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CommentError.invalidResponse
            }

            logResponse(data, response: httpResponse, context: "deleteComment")

            switch httpResponse.statusCode {
            case 200, 204:
                print("✅ コメント削除成功: ID \(commentId)")

            case 401:
                throw CommentError.unauthorized

            case 403:
                throw CommentError.apiError(403, "このコメントを削除する権限がありません")

            case 404:
                throw CommentError.commentNotFound

            case 408:
                throw CommentError.timeout

            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw CommentError.apiError(httpResponse.statusCode, errorMessage)
            }

        } catch let error as CommentError {
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw CommentError.networkError(error)
        }
    }

    func createTextComment(postId: Int, content: String) async throws -> Comment {
        return try await createComment(postId: postId, content: content, image: nil)
    }

    func createImageComment(postId: Int, image: UIImage) async throws -> Comment {
        return try await createComment(postId: postId, content: " ", image: image)
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
}
