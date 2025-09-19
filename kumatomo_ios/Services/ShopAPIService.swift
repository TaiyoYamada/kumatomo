import Foundation

class ShopAPIService {
    static let shared = ShopAPIService()
    
    private let baseURL = APIConfig.shared.baseURLString
    private var networkMonitor: NetworkMonitor {
        NetworkMonitor.shared
    }
    private var errorManager: ErrorManager {
        ErrorManager.shared
    }
    
    // 認証トークンの取得
    private func getAuthToken() -> String {
        return AuthTokenManager.shared.token ?? ""
    }
    
    // Network connectivity check
    private func checkNetworkConnectivity() async throws {
        await MainActor.run {
            guard networkMonitor.isConnected else {
                return
            }
        }
    }
    
    // Enhanced error handling for API responses
    private func handleAPIResponse(data: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 ステータスコード: \(httpResponse.statusCode)")
        
        // Log response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📡 レスポンスJSON: \(jsonString)")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 408, 504:
            throw APIError.timeout
        case 429:
            throw APIError.rateLimitExceeded
        case 500...599:
            let message = extractErrorMessage(from: data) ?? "サーバーエラーが発生しました"
            throw APIError.serverError(message: message)
        default:
            let message = extractErrorMessage(from: data) ?? "APIエラーが発生しました"
            throw APIError.apiError(statusCode: httpResponse.statusCode, message: message)
        }
    }
    
    // Extract error message from API response
    private func extractErrorMessage(from data: Data) -> String? {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                return message
            }
        } catch {
            print("Failed to parse error response: \(error)")
        }
        return nil
    }
    
    // Retry mechanism for network requests
    private func performRequestWithRetry<T>(
        request: URLRequest,
        decoder: JSONDecoder,
        type: T.Type,
        maxRetries: Int = 3
    ) async throws -> T where T: Decodable {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                try await checkNetworkConnectivity()
                
                let (data, response) = try await APISession.shared.session.data(for: request)
                let validatedData = try handleAPIResponse(data: data, response: response)
                
                return try decoder.decode(type, from: validatedData)
            } catch {
                lastError = error
                
                // Check if error is retryable
                let shouldRetry = await networkMonitor.shouldRetryNetworkRequest(error)
                if attempt < maxRetries && shouldRetry {
                    let delay = await networkMonitor.getRetryDelay(for: error, attempt: attempt)
                    print("🔄 Retrying request in \(delay) seconds (attempt \(attempt)/\(maxRetries))")
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                } else {
                    break
                }
            }
        }
        
        // If we get here, all retries failed
        if let error = lastError {
            await errorManager.handleError(error, context: "API request failed after \(maxRetries) attempts")
            throw error
        } else {
            throw APIError.unknownError(NSError(domain: "ShopAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"]))
        }
    }
    
    // お店一覧を取得する（APIは { data: [Shop], pagination: {...} } を返す）
    func fetchShops(genre: String? = nil, latitude: Double? = nil, longitude: Double? = nil, radius: Int? = nil, page: Int = 1) async throws -> [Shop] {
        var urlComponents = URLComponents(string: "\(baseURL)/shops")!
        var queryItems: [URLQueryItem] = []
        
        if let genre = genre {
            queryItems.append(URLQueryItem(name: "genre", value: genre))
        }
        if let latitude = latitude {
            queryItems.append(URLQueryItem(name: "lat", value: String(latitude)))
        }
        if let longitude = longitude {
            queryItems.append(URLQueryItem(name: "lng", value: String(longitude)))
        }
        if let radius = radius {
            queryItems.append(URLQueryItem(name: "radius", value: String(radius)))
        }
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            print("🚨 無効なURL: \(urlComponents)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30.0
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📡 GET リクエスト: \(url.absoluteString)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        let decoder = APIHelper.makeDecoder()
        
        // Use the enhanced retry mechanism
        do {
            let response = try await performRequestWithRetry(
                request: request,
                decoder: decoder,
                type: ShopListResponse.self,
                maxRetries: 3
            )
            return response.data
        } catch let apiError as APIError {
            // Treat 404 on the list endpoint as "no shops" instead of a hard error
            if case .notFound = apiError {
                print("ℹ️ /shops returned 404 -> interpreting as empty list")
                return []
            }
            throw apiError
        } catch {
            throw error
        }
    }
    
    // お店詳細を取得する（APIは { data: Shop } を返す）
    func fetchShop(id: Int) async throws -> Shop {
        let endpoint = "\(baseURL)/shops/\(id)"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw ShopAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📡 GET リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ShopAPIError.invalidResponse
            }
            
            print("📡 ステータスコード: \(httpResponse.statusCode)")
            
            // レスポンスボディをデバッグ出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON: \(jsonString)")
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = APIHelper.makeDecoder()
                do {
                    // Prefer wrapped response
                    let wrapped = try decoder.decode(ShopResponse.self, from: data)
                    return wrapped.data
                } catch {
                    // Fallback: try decoding as plain Shop (for backward-compat)
                    do {
                        return try decoder.decode(Shop.self, from: data)
                    } catch {
                        print("🚨 デコードエラー: \(error)")
                        throw ShopAPIError.decodingError(error)
                    }
                }
            } else if httpResponse.statusCode == 404 {
                throw ShopAPIError.shopNotFound
            } else if let jsonString = String(data: data, encoding: .utf8) {
                print("🚨 エラーレスポンス: \(jsonString)")
                throw ShopAPIError.serverError("ステータスコード: \(httpResponse.statusCode), レスポンス: \(jsonString)")
            } else {
                throw ShopAPIError.serverError("ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as ShopAPIError {
            print("🚨 ShopAPIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw ShopAPIError.networkError(error)
        }
    }
    
    // お店に関連する投稿を取得する（Laravel paginate形式 { current_page, data, ... }）
    func fetchShopPosts(shopId: Int, page: Int = 1, perPage: Int = 10) async throws -> [Post] {
        let endpoint = "\(baseURL)/shops/\(shopId)/posts"
        var urlComponents = URLComponents(string: endpoint)!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        
        guard let url = urlComponents.url else {
            print("🚨 無効なURL: \(urlComponents)")
            throw ShopAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📡 GET リクエスト: \(url.absoluteString)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ShopAPIError.invalidResponse
            }
            
            print("📡 ステータスコード: \(httpResponse.statusCode)")
            
            // レスポンスボディをデバッグ出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON: \(jsonString)")
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = APIHelper.makeDecoder()
                do {
                    let envelope = try decoder.decode(PostListResponse.self, from: data)
                    return envelope.data
                } catch {
                    // フォールバック：配列直デコード（互換）
                    do {
                        return try decoder.decode([Post].self, from: data)
                    } catch {
                        print("🚨 デコードエラー: \(error)")
                        throw ShopAPIError.decodingError(error)
                    }
                }
            } else if let jsonString = String(data: data, encoding: .utf8) {
                print("🚨 エラーレスポンス: \(jsonString)")
                throw ShopAPIError.serverError("ステータスコード: \(httpResponse.statusCode), レスポンス: \(jsonString)")
            } else {
                throw ShopAPIError.serverError("ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as ShopAPIError {
            print("🚨 ShopAPIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw ShopAPIError.networkError(error)
        }
    }
    
    // お店を検索する
    func searchShops(query: String, page: Int = 1) async throws -> [Shop] {
        let endpoint = "\(baseURL)/shops/search"
        var urlComponents = URLComponents(string: endpoint)!
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page))
        ]
        
        guard let url = urlComponents.url else {
            print("🚨 無効なURL: \(urlComponents)")
            throw ShopAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📡 GET リクエスト: \(url.absoluteString)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ShopAPIError.invalidResponse
            }
            
            print("📡 ステータスコード: \(httpResponse.statusCode)")
            
            // レスポンスボディをデバッグ出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON: \(jsonString)")
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = APIHelper.makeDecoder()
                
                do {
                    return try decoder.decode([Shop].self, from: data)
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw ShopAPIError.decodingError(error)
                }
            } else if let jsonString = String(data: data, encoding: .utf8) {
                print("🚨 エラーレスポンス: \(jsonString)")
                throw ShopAPIError.serverError("ステータスコード: \(httpResponse.statusCode), レスポンス: \(jsonString)")
            } else {
                throw ShopAPIError.serverError("ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as ShopAPIError {
            print("🚨 ShopAPIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw ShopAPIError.networkError(error)
        }
    }
    
    // MARK: - Favorites API Methods
    
    /// Toggle favorite status for a shop
    func toggleFavorite(shopId: Int) async throws -> FavoriteToggleResponse {
        let endpoint = "\(baseURL)/favorites/toggle/\(shopId)"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw ShopAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📡 POST リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        let decoder = APIHelper.makeDecoder()
        
        return try await performRequestWithRetry(
            request: request,
            decoder: decoder,
            type: FavoriteToggleResponse.self,
            maxRetries: 3
        )
    }
    
    /// Fetch user's favorite shops
    func fetchFavorites(page: Int = 1) async throws -> [Favorite] {
        let endpoint = "\(baseURL)/favorites"
        var urlComponents = URLComponents(string: endpoint)!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: String(page))
        ]
        
        guard let url = urlComponents.url else {
            print("🚨 無効なURL: \(urlComponents)")
            throw ShopAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📡 GET リクエスト: \(url.absoluteString)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        let decoder = APIHelper.makeDecoder()
        
        return try await performRequestWithRetry(
            request: request,
            decoder: decoder,
            type: [Favorite].self,
            maxRetries: 3
        )
    }
    
    // MARK: - Shop Proposal API Methods
    
    /// Submit a new shop proposal
    func submitShopProposal(name: String, address: String?, genre: ShopGenre?, description: String?) async throws -> ShopProposal {
        let endpoint = "\(baseURL)/shop-proposals"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw ShopAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Request body
        let requestBody: [String: Any?] = [
            "name": name,
            "address": address,
            "genre": genre?.rawValue,
            "description": description
        ]
        
        // Remove nil values
        let cleanedBody = requestBody.compactMapValues { $0 }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: cleanedBody)
        } catch {
            throw APIError.encodingError(error)
        }
        
        print("📡 POST リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        print("📡 ボディ: \(cleanedBody)")
        
        let decoder = APIHelper.makeDecoder()
        
        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            let validatedData = try handleAPIResponse(data: data, response: response)
            
            // Parse the response which includes both data and message
            if let json = try JSONSerialization.jsonObject(with: validatedData) as? [String: Any],
               let proposalData = json["data"] as? [String: Any] {
                let proposalJsonData = try JSONSerialization.data(withJSONObject: proposalData)
                return try decoder.decode(ShopProposal.self, from: proposalJsonData)
            } else {
                // Fallback to direct decoding
                return try decoder.decode(ShopProposal.self, from: validatedData)
            }
        } catch {
            await errorManager.handleError(error, context: "Shop proposal submission failed")
            throw error
        }
    }
    
    /// Fetch user's shop proposals
    func fetchShopProposals(page: Int = 1) async throws -> [ShopProposal] {
        let endpoint = "\(baseURL)/shop-proposals"
        var urlComponents = URLComponents(string: endpoint)!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: String(page))
        ]
        
        guard let url = urlComponents.url else {
            print("🚨 無効なURL: \(urlComponents)")
            throw ShopAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📡 GET リクエスト: \(url.absoluteString)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        let decoder = APIHelper.makeDecoder()
        
        return try await performRequestWithRetry(
            request: request,
            decoder: decoder,
            type: [ShopProposal].self,
            maxRetries: 3
        )
    }
    
    /// Get proposal status for user feedback
    func fetchProposalStatus() async throws -> ProposalStatusResponse {
        let endpoint = "\(baseURL)/shop-proposals-status"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw ShopAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📡 GET リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        let decoder = APIHelper.makeDecoder()
        
        return try await performRequestWithRetry(
            request: request,
            decoder: decoder,
            type: ProposalStatusResponse.self,
            maxRetries: 3
        )
    }
    
    /// Update a shop proposal (only if pending)
    func updateShopProposal(id: Int, name: String, address: String?, genre: ShopGenre?, description: String?) async throws -> ShopProposal {
        let endpoint = "\(baseURL)/shop-proposals/\(id)"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw ShopAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Request body
        let requestBody: [String: Any?] = [
            "name": name,
            "address": address,
            "genre": genre?.rawValue,
            "description": description
        ]
        
        // Remove nil values
        let cleanedBody = requestBody.compactMapValues { $0 }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: cleanedBody)
        } catch {
            throw APIError.encodingError(error)
        }
        
        print("📡 PUT リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        print("📡 ボディ: \(cleanedBody)")
        
        let decoder = APIHelper.makeDecoder()
        
        return try await performRequestWithRetry(
            request: request,
            decoder: decoder,
            type: ShopProposal.self,
            maxRetries: 3
        )
    }
    
    /// Delete a shop proposal (only if pending)
    func deleteShopProposal(id: Int) async throws {
        let endpoint = "\(baseURL)/shop-proposals/\(id)"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw ShopAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📡 DELETE リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            _ = try handleAPIResponse(data: data, response: response)
        } catch {
            await errorManager.handleError(error, context: "Shop proposal deletion failed")
            throw error
        }
    }

    // MARK: - Admin: Shop Proposal Management (for admin users)

    /// Fetch all shop proposals for admin review
    func fetchAdminShopProposals(status: ProposalStatus? = nil,
                                 search: String? = nil,
                                 page: Int = 1,
                                 perPage: Int = 20) async throws -> [ShopProposal] {
        var urlComponents = URLComponents(string: "\(baseURL)/admin/shop-proposals")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        if let status = status { queryItems.append(URLQueryItem(name: "status", value: status.rawValue)) }
        if let search = search, !search.isEmpty { queryItems.append(URLQueryItem(name: "search", value: search)) }
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            print("🚨 無効なURL: \(urlComponents)")
            throw ShopAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        print("📡 GET リクエスト: \(url.absoluteString)")
        let decoder = APIHelper.makeDecoder()
        return try await performRequestWithRetry(
            request: request,
            decoder: decoder,
            type: [ShopProposal].self,
            maxRetries: 3
        )
    }

    /// Approve a shop proposal (admin)
    func approveAdminShopProposal(id: Int, adminNotes: String? = nil) async throws -> AdminApproveResponse {
        let endpoint = "\(baseURL)/admin/shop-proposals/\(id)/approve"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw ShopAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // Optional body
        if let notes = adminNotes {
            let body: [String: Any] = ["admin_notes": notes]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        print("📡 POST リクエスト: \(endpoint)")
        let decoder = APIHelper.makeDecoder()
        return try await performRequestWithRetry(
            request: request,
            decoder: decoder,
            type: AdminApproveResponse.self,
            maxRetries: 3
        )
    }

    /// Reject a shop proposal (admin)
    func rejectAdminShopProposal(id: Int, adminNotes: String) async throws -> ShopProposal {
        let endpoint = "\(baseURL)/admin/shop-proposals/\(id)/reject"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw ShopAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = ["admin_notes": adminNotes]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📡 POST リクエスト: \(endpoint)")
        let decoder = APIHelper.makeDecoder()
        return try await performRequestWithRetry(
            request: request,
            decoder: decoder,
            type: ShopProposal.self,
            maxRetries: 3
        )
    }
}
