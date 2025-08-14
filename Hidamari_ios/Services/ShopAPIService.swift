import Foundation

class ShopAPIService {
    static let shared = ShopAPIService()
    
    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://localhost/api"
    private let networkMonitor = NetworkMonitor.shared
    private let errorManager = ErrorManager.shared
    
    // 認証トークンの取得
    private func getAuthToken() -> String {
        return AuthTokenManager.shared.token ?? ""
    }
    
    // Network connectivity check
    private func checkNetworkConnectivity() async throws {
        guard await networkMonitor.checkConnectivity() else {
            throw APIError.networkError(URLError(.notConnectedToInternet))
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
    
    // お店一覧を取得する
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
        return try await performRequestWithRetry(
            request: request,
            decoder: decoder,
            type: [Shop].self,
            maxRetries: 3
        )
    }
    
    // お店詳細を取得する
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
                    return try decoder.decode(Shop.self, from: data)
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw ShopAPIError.decodingError(error)
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
    
    // お店に関連する投稿を取得する
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
                    return try decoder.decode([Post].self, from: data)
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
}
