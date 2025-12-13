import Foundation

class EngagementAPIService {
    static let shared = EngagementAPIService()

    private let baseURL = APIConfig.shared.baseURLString

    private init() {}

    private func mapNetworkError(_ error: Error) -> EngagementError {
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return .requestCancelled
        }
        return .networkError(error)
    }

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
        print("💖 [\(context)] リクエスト: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        print("💖 [\(context)] ヘッダー: \(request.allHTTPHeaderFields ?? [:])")

        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("💖 [\(context)] ボディ: \(bodyString)")
        }
    }

    private func logResponse(_ data: Data, response: HTTPURLResponse, context: String) {
        print("💖 [\(context)] ステータスコード: \(response.statusCode)")

        if let jsonString = String(data: data, encoding: .utf8) {
            print("💖 [\(context)] レスポンス: \(jsonString)")
        }
    }

    private func decodePostsArray(from data: Data) throws -> [Post] {
        let decoder = APIHelper.makeDecoder()
        if let posts = try? decoder.decode([Post].self, from: data) {
            return posts
        }
        let json = try JSONSerialization.jsonObject(with: data, options: [])

        func attemptDecode(from any: Any) -> [Post]? {
            guard let array = any as? [Any] else { return nil }
            let dictArray = array.compactMap { $0 as? [String: Any] }
            guard !dictArray.isEmpty else { return [] }
            if let arrayData = try? JSONSerialization.data(withJSONObject: dictArray) {
                return try? decoder.decode([Post].self, from: arrayData)
            }
            return nil
        }

        if let dict = json as? [String: Any] {
            let keys = ["data", "posts", "items", "results", "list", "liked_posts", "bookmarked_posts"]
            for key in keys {
                if let val = dict[key] {
                    if let decoded = attemptDecode(from: val) { return decoded }
                    if let nested = val as? [String: Any] {
                        for innerKey in keys {
                            if let innerVal = nested[innerKey],
                               let decoded = attemptDecode(from: innerVal) { return decoded }
                        }
                    }
                }
            }
            for (_, value) in dict {
                if let decoded = attemptDecode(from: value) { return decoded }
                if let nested = value as? [String: Any] {
                    for (_, v2) in nested {
                        if let decoded = attemptDecode(from: v2) { return decoded }
                    }
                }
            }
        }
        throw EngagementError.decodingError(DecodingError.typeMismatch(
            [Post].self,
            .init(codingPath: [], debugDescription: "Expected posts array but got wrapped/different shape")
        ))
    }

    func toggleLike(postId: Int) async throws -> LikeResponse {
        let endpoint = "\(baseURL)/posts/\(postId)/like"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw EngagementError.invalidURL
        }

        let request = createAuthorizedRequest(url: url, method: "POST")
        logRequest(request, context: "toggleLike")

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EngagementError.invalidResponse
            }

            logResponse(data, response: httpResponse, context: "toggleLike")

            switch httpResponse.statusCode {
            case 200, 201:
                let decoder = APIHelper.makeDecoder()
                do {
                    let likeResponse = try decoder.decode(LikeResponse.self, from: data)
                    print("✅ いいね切り替え成功: \(likeResponse.isLiked ? "いいね" : "いいね解除") (合計: \(likeResponse.likeCount))")
                    return likeResponse
                } catch {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let root = (json["data"] as? [String: Any]) ?? json
                        let isLiked = (root["is_liked"] as? Bool) ?? (root["isLiked"] as? Bool) ?? false
                        let likeCount = (root["like_count"] as? Int) ?? (root["likeCount"] as? Int) ?? 0
                        let fallback = LikeResponse(isLiked: isLiked, likeCount: likeCount)
                        return fallback
                    }
                    print("🚨 デコードエラー: \(error)")
                    throw EngagementError.decodingError(error)
                }

            case 401:
                throw EngagementError.unauthorized

            case 404:
                throw EngagementError.postNotFound

            case 408:
                throw EngagementError.timeout

            case 409:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    if message.contains("already liked") {
                        throw EngagementError.alreadyLiked
                    }
                }
                throw EngagementError.apiError(409, "操作が競合しました")

            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw EngagementError.apiError(httpResponse.statusCode, errorMessage)
            }

        } catch let error as EngagementError {
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw mapNetworkError(error)
        }
    }

    func unlikePost(postId: Int) async throws -> LikeResponse {
        let endpoint = "\(baseURL)/posts/\(postId)/like"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw EngagementError.invalidURL
        }

        let request = createAuthorizedRequest(url: url, method: "DELETE")
        logRequest(request, context: "unlikePost")

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EngagementError.invalidResponse
            }

            logResponse(data, response: httpResponse, context: "unlikePost")

            switch httpResponse.statusCode {
            case 200, 204:
                let decoder = APIHelper.makeDecoder()
                do {
                    let likeResponse = try decoder.decode(LikeResponse.self, from: data)
                    print("✅ いいね解除成功 (合計: \(likeResponse.likeCount))")
                    return likeResponse
                } catch {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let root = (json["data"] as? [String: Any]) ?? json
                        let isLiked = (root["is_liked"] as? Bool) ?? (root["isLiked"] as? Bool) ?? false
                        let likeCount = (root["like_count"] as? Int) ?? (root["likeCount"] as? Int) ?? 0
                        let fallback = LikeResponse(isLiked: isLiked, likeCount: likeCount)
                        print("✅ いいね解除成功(フォールバック): (合計: \(fallback.likeCount))")
                        return fallback
                    }
                    print("🚨 デコードエラー: \(error)")
                    throw EngagementError.decodingError(error)
                }

            case 401:
                throw EngagementError.unauthorized

            case 404:
                throw EngagementError.postNotFound

            case 408:
                throw EngagementError.timeout

            case 409:
                throw EngagementError.notLiked

            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw EngagementError.apiError(httpResponse.statusCode, errorMessage)
            }

        } catch let error as EngagementError {
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw mapNetworkError(error)
        }
    }

    func fetchLikedPosts() async throws -> [Post] {
        let endpoint = "\(baseURL)/user/liked-posts"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw EngagementError.invalidURL
        }

        let request = createAuthorizedRequest(url: url)
        logRequest(request, context: "fetchLikedPosts")

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EngagementError.invalidResponse
            }

            logResponse(data, response: httpResponse, context: "fetchLikedPosts")

            switch httpResponse.statusCode {
            case 200:
                do {
                    let posts = try decodePostsArray(from: data)
                    print("✅ いいねした投稿取得成功: \(posts.count)件")
                    return posts
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw EngagementError.decodingError(error)
                }

            case 401:
                throw EngagementError.unauthorized

            case 408:
                throw EngagementError.timeout

            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw EngagementError.apiError(httpResponse.statusCode, errorMessage)
            }

        } catch let error as EngagementError {
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw mapNetworkError(error)
        }
    }

    func toggleBookmark(postId: Int) async throws -> BookmarkResponse {
        let endpoint = "\(baseURL)/posts/\(postId)/bookmark"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw EngagementError.invalidURL
        }

        let request = createAuthorizedRequest(url: url, method: "POST")
        logRequest(request, context: "toggleBookmark")

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EngagementError.invalidResponse
            }

            logResponse(data, response: httpResponse, context: "toggleBookmark")

            switch httpResponse.statusCode {
            case 200, 201:
                let decoder = APIHelper.makeDecoder()
                do {
                    let bookmarkResponse = try decoder.decode(BookmarkResponse.self, from: data)
                    print(
                        "✅ ブックマーク切り替え成功: \(bookmarkResponse.isBookmarked ? "ブックマーク" : "ブックマーク解除") (合計: \(bookmarkResponse.bookmarkCount))"
                    )
                    return bookmarkResponse
                } catch {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let root = (json["data"] as? [String: Any]) ?? json
                        let isBookmarked = (root["is_bookmarked"] as? Bool)
                            ?? (root["isBookmarked"] as? Bool)
                            ?? false
                        let bookmarkCount = (root["bookmark_count"] as? Int)
                            ?? (root["bookmarkCount"] as? Int)
                            ?? 0
                        let fallback = BookmarkResponse(isBookmarked: isBookmarked, bookmarkCount: bookmarkCount)
                        print(
                            "✅ ブックマーク切り替え成功(フォールバック): \(fallback.isBookmarked ? "ブックマーク" : "ブックマーク解除") (合計: \(fallback.bookmarkCount))"
                        )
                        return fallback
                    }
                    print("🚨 デコードエラー: \(error)")
                    throw EngagementError.decodingError(error)
                }

            case 401:
                throw EngagementError.unauthorized

            case 404:
                throw EngagementError.postNotFound

            case 408:
                throw EngagementError.timeout

            case 409:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    if message.contains("already bookmarked") {
                        throw EngagementError.alreadyBookmarked
                    }
                }
                throw EngagementError.apiError(409, "操作が競合しました")

            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw EngagementError.apiError(httpResponse.statusCode, errorMessage)
            }

        } catch let error as EngagementError {
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw mapNetworkError(error)
        }
    }

    func unbookmarkPost(postId: Int) async throws -> BookmarkResponse {
        let endpoint = "\(baseURL)/posts/\(postId)/bookmark"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw EngagementError.invalidURL
        }

        let request = createAuthorizedRequest(url: url, method: "DELETE")
        logRequest(request, context: "unbookmarkPost")

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EngagementError.invalidResponse
            }

            logResponse(data, response: httpResponse, context: "unbookmarkPost")

            switch httpResponse.statusCode {
            case 200, 204:
                let decoder = APIHelper.makeDecoder()
                do {
                    let bookmarkResponse = try decoder.decode(BookmarkResponse.self, from: data)
                    print("✅ ブックマーク解除成功 (合計: \(bookmarkResponse.bookmarkCount))")
                    return bookmarkResponse
                } catch {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let root = (json["data"] as? [String: Any]) ?? json
                        let isBookmarked = (root["is_bookmarked"] as? Bool) ?? (root["isBookmarked"] as? Bool) ?? false
                        let bookmarkCount = (root["bookmark_count"] as? Int) ?? (root["bookmarkCount"] as? Int) ?? 0
                        let fallback = BookmarkResponse(isBookmarked: isBookmarked, bookmarkCount: bookmarkCount)
                        print("✅ ブックマーク解除成功(フォールバック): (合計: \(fallback.bookmarkCount))")
                        return fallback
                    }
                    print("🚨 デコードエラー: \(error)")
                    throw EngagementError.decodingError(error)
                }

            case 401:
                throw EngagementError.unauthorized

            case 404:
                throw EngagementError.postNotFound

            case 408:
                throw EngagementError.timeout

            case 409:
                throw EngagementError.notBookmarked

            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw EngagementError.apiError(httpResponse.statusCode, errorMessage)
            }

        } catch let error as EngagementError {
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw mapNetworkError(error)
        }
    }

    func fetchBookmarkedPosts() async throws -> [Post] {
        let endpoint = "\(baseURL)/user/bookmarked-posts"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw EngagementError.invalidURL
        }

        let request = createAuthorizedRequest(url: url)
        logRequest(request, context: "fetchBookmarkedPosts")

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EngagementError.invalidResponse
            }

            logResponse(data, response: httpResponse, context: "fetchBookmarkedPosts")

            switch httpResponse.statusCode {
            case 200:
                do {
                    let posts = try decodePostsArray(from: data)
                    print("✅ ブックマークした投稿取得成功: \(posts.count)件")
                    return posts
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw EngagementError.decodingError(error)
                }

            case 401:
                throw EngagementError.unauthorized

            case 408:
                throw EngagementError.timeout

            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw EngagementError.apiError(httpResponse.statusCode, errorMessage)
            }

        } catch let error as EngagementError {
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw mapNetworkError(error)
        }
    }

    func optimisticToggleLike(
        postId: Int,
        currentState: Bool,
        currentCount: Int
    ) async -> (success: Bool, response: LikeResponse?, error: EngagementError?) {
        do {
            let response = try await toggleLike(postId: postId)
            return (success: true, response: response, error: nil)
        } catch let error as EngagementError {
            let rollbackResponse = LikeResponse(
                isLiked: currentState,
                likeCount: currentCount
            )
            return (success: false, response: rollbackResponse, error: error)
        } catch {
            let rollbackResponse = LikeResponse(
                isLiked: currentState,
                likeCount: currentCount
            )
            return (success: false, response: rollbackResponse, error: EngagementError.unknownError(error))
        }
    }

    func optimisticToggleBookmark(
        postId: Int,
        currentState: Bool,
        currentCount: Int
    ) async -> (success: Bool, response: BookmarkResponse?, error: EngagementError?) {
        do {
            let response = try await toggleBookmark(postId: postId)
            return (success: true, response: response, error: nil)
        } catch let error as EngagementError {
            let rollbackResponse = BookmarkResponse(
                isBookmarked: currentState,
                bookmarkCount: currentCount
            )
            return (success: false, response: rollbackResponse, error: error)
        } catch {
            let rollbackResponse = BookmarkResponse(
                isBookmarked: currentState,
                bookmarkCount: currentCount
            )
            return (success: false, response: rollbackResponse, error: EngagementError.unknownError(error))
        }
    }

    func isPostLiked(postId: Int) async throws -> Bool {
        let likedPosts = try await fetchLikedPosts()
        return likedPosts.contains { $0.id == postId }
    }

    func isPostBookmarked(postId: Int) async throws -> Bool {
        let bookmarkedPosts = try await fetchBookmarkedPosts()
        return bookmarkedPosts.contains { $0.id == postId }
    }

    func batchCheckEngagementStatus(postIds: [Int]) async throws -> [Int: (isLiked: Bool, isBookmarked: Bool)] {
        async let likedPosts = fetchLikedPosts()
        async let bookmarkedPosts = fetchBookmarkedPosts()

        let (liked, bookmarked) = try await (likedPosts, bookmarkedPosts)

        let likedPostIds = Set(liked.map(\.id))
        let bookmarkedPostIds = Set(bookmarked.map(\.id))

        var result: [Int: (isLiked: Bool, isBookmarked: Bool)] = [:]

        for postId in postIds {
            result[postId] = (
                isLiked: likedPostIds.contains(postId),
                isBookmarked: bookmarkedPostIds.contains(postId)
            )
        }

        return result
    }
}
