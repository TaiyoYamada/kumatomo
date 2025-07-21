import Foundation

class PostAPIService {
    static let shared = PostAPIService()
    
    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8000/api"
    
    // 認証トークンの取得
    private func getAuthToken() -> String {
        return AuthTokenManager.shared.token ?? ""
    }
    
    // ストーリーを投稿する（画像URL、タイトル、タグに対応）
    func createPost(userId: Int, title: String, content: String, imageUrl: String? = nil, tags: [String] = []) async throws -> Post {
        let endpoint = "\(baseURL)/stories"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw PostAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ 認証トークンがありません")
        }
        
        // リクエストボディの作成
        var body: [String: Any] = [
            "user_id": userId,
            "title": title,
            "content": content
        ]
        
        // 画像URLがある場合は追加
        if let imageUrl = imageUrl, !imageUrl.isEmpty {
            body["image_url"] = imageUrl
        }
        
        // タグがある場合は追加
        if !tags.isEmpty {
            body["tags"] = tags
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📡 POST リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        print("📡 ボディ: \(body)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PostAPIError.invalidResponse
            }
            
            print("📡 ステータスコード: \(httpResponse.statusCode)")
            
            // レスポンスボディをデバッグ出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON: \(jsonString)")
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // APIHelperを使用してデコード
                let decoder = APIHelper.makeDecoder()
                
                do {
                    return try decoder.decode(Post.self, from: data)
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw PostAPIError.decodingError(error)
                }
            } else if let jsonString = String(data: data, encoding: .utf8) {
                // エラーレスポンスの詳細を確認
                print("🚨 エラーレスポンス: \(jsonString)")
                throw PostAPIError.serverError("ステータスコード: \(httpResponse.statusCode), レスポンス: \(jsonString)")
            } else {
                throw PostAPIError.serverError("ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as PostAPIError {
            print("🚨 PostAPIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw PostAPIError.networkError(error)
        }
    }
    
    // 全ユーザーのストーリーを取得する
    func fetchAllStories() async throws -> [Post] {
        let endpoint = "\(baseURL)/stories"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw PostAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ 認証トークンがありません")
        }
        
        print("📡 GET リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PostAPIError.invalidResponse
            }
            
            print("📡 ステータスコード: \(httpResponse.statusCode)")
            
            // レスポンスボディをデバッグ出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON: \(jsonString)")
            }
            
            if httpResponse.statusCode == 200 {
                // APIHelperを使用してデコード
                let decoder = APIHelper.makeDecoder()
                
                do {
                    return try decoder.decode([Post].self, from: data)
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, _):
                            print("🔑 キーが見つかりません: \(key)")
                        case .typeMismatch(let type, _):
                            print("📊 型の不一致: \(type)")
                        case .valueNotFound(let type, _):
                            print("⚠️ 値が見つかりません: \(type)")
                        case .dataCorrupted(let context):
                            print("🔄 データ破損: \(context)")
                        @unknown default:
                            print("🧩 その他のデコードエラー")
                        }
                    }
                    throw PostAPIError.decodingError(error)
                }
            } else if let jsonString = String(data: data, encoding: .utf8) {
                print("🚨 エラーレスポンス: \(jsonString)")
                throw PostAPIError.serverError("ステータスコード: \(httpResponse.statusCode), レスポンス: \(jsonString)")
            } else {
                throw PostAPIError.serverError("ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as PostAPIError {
            print("🚨 PostAPIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw PostAPIError.networkError(error)
        }
    }
    
    // 特定ユーザーのストーリーを取得する
    func fetchUserStories(userId: Int) async throws -> [Post] {
        let endpoint = "\(baseURL)/users/\(userId)/stories"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw PostAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ 認証トークンがありません")
        }
        
        print("📡 GET リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PostAPIError.invalidResponse
            }
            
            print("📡 ステータスコード: \(httpResponse.statusCode)")
            
            // レスポンスボディをデバッグ出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON: \(jsonString)")
            }
            
            if httpResponse.statusCode == 200 {
                // APIHelperを使用してデコード
                let decoder = APIHelper.makeDecoder()
                
                do {
                    return try decoder.decode([Post].self, from: data)
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, _):
                            print("🔑 キーが見つかりません: \(key)")
                        case .typeMismatch(let type, _):
                            print("📊 型の不一致: \(type)")
                        case .valueNotFound(let type, _):
                            print("⚠️ 値が見つかりません: \(type)")
                        case .dataCorrupted(let context):
                            print("🔄 データ破損: \(context)")
                        @unknown default:
                            print("🧩 その他のデコードエラー")
                        }
                    }
                    throw PostAPIError.decodingError(error)
                }
            } else if let jsonString = String(data: data, encoding: .utf8) {
                print("🚨 エラーレスポンス: \(jsonString)")
                throw PostAPIError.serverError("ステータスコード: \(httpResponse.statusCode), レスポンス: \(jsonString)")
            } else {
                throw PostAPIError.serverError("ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as PostAPIError {
            print("🚨 PostAPIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw PostAPIError.networkError(error)
        }
    }
}
