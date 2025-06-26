import Foundation

class StoryAPIService {
    static let shared = StoryAPIService()
    
    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8000/api"
    
    // 認証トークンの取得
    private func getAuthToken() -> String {
        return AuthTokenManager.shared.token ?? ""
    }
    
    // ストーリーを投稿する
    func postStory(userId: Int, content: String) async throws -> Story {
        let endpoint = "\(baseURL)/stories"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw StoryAPIError.invalidURL
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
        let body: [String: Any] = [
            "user_id": userId,
            "content": content
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📡 POST リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        print("📡 ボディ: \(body)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StoryAPIError.invalidResponse
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
                    return try decoder.decode(Story.self, from: data)
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw StoryAPIError.decodingError(error)
                }
            } else if let jsonString = String(data: data, encoding: .utf8) {
                // エラーレスポンスの詳細を確認
                print("🚨 エラーレスポンス: \(jsonString)")
                throw StoryAPIError.serverError("ステータスコード: \(httpResponse.statusCode), レスポンス: \(jsonString)")
            } else {
                throw StoryAPIError.serverError("ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as StoryAPIError {
            print("🚨 StoryAPIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw StoryAPIError.networkError(error)
        }
    }
    
    // 全ユーザーのストーリーを取得する
    func fetchAllStories() async throws -> [Story] {
        let endpoint = "\(baseURL)/stories"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw StoryAPIError.invalidURL
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
                throw StoryAPIError.invalidResponse
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
                    return try decoder.decode([Story].self, from: data)
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
                    throw StoryAPIError.decodingError(error)
                }
            } else if let jsonString = String(data: data, encoding: .utf8) {
                print("🚨 エラーレスポンス: \(jsonString)")
                throw StoryAPIError.serverError("ステータスコード: \(httpResponse.statusCode), レスポンス: \(jsonString)")
            } else {
                throw StoryAPIError.serverError("ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as StoryAPIError {
            print("🚨 StoryAPIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw StoryAPIError.networkError(error)
        }
    }
    
    // 特定ユーザーのストーリーを取得する
    func fetchUserStories(userId: Int) async throws -> [Story] {
        let endpoint = "\(baseURL)/users/\(userId)/stories"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw StoryAPIError.invalidURL
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
                throw StoryAPIError.invalidResponse
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
                    return try decoder.decode([Story].self, from: data)
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw StoryAPIError.decodingError(error)
                }
            } else if let jsonString = String(data: data, encoding: .utf8) {
                print("🚨 エラーレスポンス: \(jsonString)")
                throw StoryAPIError.serverError("ステータスコード: \(httpResponse.statusCode), レスポンス: \(jsonString)")
            } else {
                throw StoryAPIError.serverError("ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as StoryAPIError {
            print("🚨 StoryAPIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw StoryAPIError.networkError(error)
        }
    }
}
