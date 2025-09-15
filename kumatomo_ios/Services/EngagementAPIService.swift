import Foundation

class EngagementAPIService {
    static let shared = EngagementAPIService()
    
    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8000/api"
    
    private init() {}

    // MARK: - Error Mapping

    private func mapNetworkError(_ error: Error) -> EngagementError {
        if let urlError = error as? URLError, urlError.code == .cancelled {
            // Treat task cancellation as a benign event; higher layers will ignore
            return .requestCancelled
        }
        return .networkError(error)
    }
    
    // MARK: - Authentication
    
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
    
    // MARK: - Logging
    
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
    
    // MARK: - Flexible Decoding Helpers
    private func decodePostsArray(from data: Data) throws -> [Post] {
        let decoder = APIHelper.makeDecoder()
        // Try direct array first
        if let posts = try? decoder.decode([Post].self, from: data) {
            return posts
        }
        // Fallbacks for wrapped responses
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
                            if let innerVal = nested[innerKey], let decoded = attemptDecode(from: innerVal) { return decoded }
                        }
                    }
                }
            }
            // scan shallow values
            for (_, value) in dict {
                if let decoded = attemptDecode(from: value) { return decoded }
                if let nested = value as? [String: Any] {
                    for (_, v2) in nested { if let decoded = attemptDecode(from: v2) { return decoded } }
                }
            }
        }
        throw EngagementError.decodingError(DecodingError.typeMismatch([Post].self, .init(codingPath: [], debugDescription: "Expected posts array but got wrapped/different shape")))
    }
    
    // MARK: - Like API Methods
    
    /// Toggle like status for a post
    /// - Parameter postId: The ID of the post to like/unlike
    /// - Returns: LikeResponse containing the new like status and count
    /// - Throws: EngagementError for various failure scenarios
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
//                        print("✅ いいね切り替え成功(フォールバック): \(fallback.isLiked ? \"いいね\" : \"いいね解除\") (合計: \(fallback.likeCount))")
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
                // Conflict - already liked/unliked
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
    
    /// Unlike a post (explicit unlike)
    /// - Parameter postId: The ID of the post to unlike
    /// - Returns: LikeResponse containing the new like status and count
    /// - Throws: EngagementError for various failure scenarios
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
    
    /// Fetch user's liked posts
    /// - Returns: Array of Post objects that the user has liked
    /// - Throws: EngagementError for various failure scenarios
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
    
    // MARK: - Bookmark API Methods
    
    /// Toggle bookmark status for a post
    /// - Parameter postId: The ID of the post to bookmark/unbookmark
    /// - Returns: BookmarkResponse containing the new bookmark status and count
    /// - Throws: EngagementError for various failure scenarios
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
                    print("✅ ブックマーク切り替え成功: \(bookmarkResponse.isBookmarked ? "ブックマーク" : "ブックマーク解除") (合計: \(bookmarkResponse.bookmarkCount))")
                    return bookmarkResponse
                } catch {
                    // Fallback for APIs that wrap payload or use camelCase keys
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let root = (json["data"] as? [String: Any]) ?? json
                        let isBookmarked = (root["is_bookmarked"] as? Bool)
                            ?? (root["isBookmarked"] as? Bool)
                            ?? false
                        let bookmarkCount = (root["bookmark_count"] as? Int)
                            ?? (root["bookmarkCount"] as? Int)
                            ?? 0
                        let fallback = BookmarkResponse(isBookmarked: isBookmarked, bookmarkCount: bookmarkCount)
                        print("✅ ブックマーク切り替え成功(フォールバック): \(fallback.isBookmarked ? "ブックマーク" : "ブックマーク解除") (合計: \(fallback.bookmarkCount))")
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
                // Conflict - already bookmarked/unbookmarked
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
    
    /// Remove bookmark from a post (explicit unbookmark)
    /// - Parameter postId: The ID of the post to unbookmark
    /// - Returns: BookmarkResponse containing the new bookmark status and count
    /// - Throws: EngagementError for various failure scenarios
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
    
    /// Fetch user's bookmarked posts
    /// - Returns: Array of Post objects that the user has bookmarked
    /// - Throws: EngagementError for various failure scenarios
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
    
    // MARK: - Optimistic Update Support
    
    /// Optimistically toggle like with rollback capability
    /// - Parameters:
    ///   - postId: The ID of the post to like/unlike
    ///   - currentState: Current like state for rollback
    ///   - currentCount: Current like count for rollback
    /// - Returns: Tuple containing success status and final LikeResponse
    func optimisticToggleLike(
        postId: Int,
        currentState: Bool,
        currentCount: Int
    ) async -> (success: Bool, response: LikeResponse?, error: EngagementError?) {
        do {
            let response = try await toggleLike(postId: postId)
            return (success: true, response: response, error: nil)
        } catch let error as EngagementError {
            // Return rollback values
            let rollbackResponse = LikeResponse(
                isLiked: currentState,
                likeCount: currentCount
            )
            return (success: false, response: rollbackResponse, error: error)
        } catch {
            // Return rollback values for unexpected errors
            let rollbackResponse = LikeResponse(
                isLiked: currentState,
                likeCount: currentCount
            )
            return (success: false, response: rollbackResponse, error: EngagementError.unknownError(error))
        }
    }
    
    /// Optimistically toggle bookmark with rollback capability
    /// - Parameters:
    ///   - postId: The ID of the post to bookmark/unbookmark
    ///   - currentState: Current bookmark state for rollback
    ///   - currentCount: Current bookmark count for rollback
    /// - Returns: Tuple containing success status and final BookmarkResponse
    func optimisticToggleBookmark(
        postId: Int,
        currentState: Bool,
        currentCount: Int
    ) async -> (success: Bool, response: BookmarkResponse?, error: EngagementError?) {
        do {
            let response = try await toggleBookmark(postId: postId)
            return (success: true, response: response, error: nil)
        } catch let error as EngagementError {
            // Return rollback values
            let rollbackResponse = BookmarkResponse(
                isBookmarked: currentState,
                bookmarkCount: currentCount
            )
            return (success: false, response: rollbackResponse, error: error)
        } catch {
            // Return rollback values for unexpected errors
            let rollbackResponse = BookmarkResponse(
                isBookmarked: currentState,
                bookmarkCount: currentCount
            )
            return (success: false, response: rollbackResponse, error: EngagementError.unknownError(error))
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Check if user has liked a specific post
    /// - Parameter postId: The ID of the post to check
    /// - Returns: Boolean indicating if the post is liked by current user
    /// - Throws: EngagementError for various failure scenarios
    func isPostLiked(postId: Int) async throws -> Bool {
        let likedPosts = try await fetchLikedPosts()
        return likedPosts.contains { $0.id == postId }
    }
    
    /// Check if user has bookmarked a specific post
    /// - Parameter postId: The ID of the post to check
    /// - Returns: Boolean indicating if the post is bookmarked by current user
    /// - Throws: EngagementError for various failure scenarios
    func isPostBookmarked(postId: Int) async throws -> Bool {
        let bookmarkedPosts = try await fetchBookmarkedPosts()
        return bookmarkedPosts.contains { $0.id == postId }
    }
    
    /// Batch check engagement status for multiple posts
    /// - Parameter postIds: Array of post IDs to check
    /// - Returns: Dictionary mapping post ID to engagement status
    /// - Throws: EngagementError for various failure scenarios
    func batchCheckEngagementStatus(postIds: [Int]) async throws -> [Int: (isLiked: Bool, isBookmarked: Bool)] {
        async let likedPosts = fetchLikedPosts()
        async let bookmarkedPosts = fetchBookmarkedPosts()
        
        let (liked, bookmarked) = try await (likedPosts, bookmarkedPosts)
        
        let likedPostIds = Set(liked.map { $0.id })
        let bookmarkedPostIds = Set(bookmarked.map { $0.id })
        
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
