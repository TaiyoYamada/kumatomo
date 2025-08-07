import Foundation

class ShopAPIService {
    static let shared = ShopAPIService()
    
    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8000/api"
    
    // 認証トークンの取得
    private func getAuthToken() -> String {
        return AuthTokenManager.shared.token ?? ""
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
            let (data, response) = try await URLSession.shared.data(for: request)
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
            let (data, response) = try await URLSession.shared.data(for: request)
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
            let (data, response) = try await URLSession.shared.data(for: request)
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
            let (data, response) = try await URLSession.shared.data(for: request)
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