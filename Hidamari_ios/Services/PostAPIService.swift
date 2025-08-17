import Foundation

class PostAPIService {
    static let shared = PostAPIService()
    
    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8000/api"
    
    // 認証トークンの取得
    private func getAuthToken() -> String {
        return AuthTokenManager.shared.token ?? ""
    }
    
    // デバッグ用：JSONレスポンスの構造を詳しく確認
    private func debugJSONResponse(_ data: Data, context: String) {
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📡 レスポンスJSON (\(context)): \(jsonString)")
            
            // JSONの構造を詳しく確認
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                if let postsArray = jsonObject as? [[String: Any]] {
                    print("📊 投稿数: \(postsArray.count)")
                    if let firstPost = postsArray.first {
                        print("📊 最初の投稿のキー: \(firstPost.keys.sorted())")
                        if let images = firstPost["images"] as? [[String: Any]] {
                            print("📊 画像数: \(images.count)")
                            if let firstImage = images.first {
                                print("📊 最初の画像のキー: \(firstImage.keys.sorted())")
                            }
                        }
                    }
                } else if let singlePost = jsonObject as? [String: Any] {
                    print("📊 単一投稿のキー: \(singlePost.keys.sorted())")
                    if let images = singlePost["images"] as? [[String: Any]] {
                        print("📊 画像数: \(images.count)")
                        if let firstImage = images.first {
                            print("📊 最初の画像のキー: \(firstImage.keys.sorted())")
                        }
                    }
                }
            }
        }
    }
    
    // 投稿を作成する（複数画像対応）
    func createPostWithMultipleImages(userId: Int, content: String, shopId: Int? = nil, imageUrls: [String], tags: [String] = []) async throws -> Post {
        let endpoint = "\(baseURL)/posts"
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
            "content": content,
            "image_urls": imageUrls
        ]
        
        // お店IDがある場合は追加
        if let shopId = shopId {
            body["shop_id"] = shopId
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
            let (data, response) = try await APISession.shared.session.data(for: request)
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
    
    // ストーリーを投稿する（画像URL、タイトル、タグに対応）
    func createPost(userId: Int, content: String, imageUrl: String? = nil, tags: [String] = []) async throws -> Post {
        let endpoint = "\(baseURL)/posts"
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
            let (data, response) = try await APISession.shared.session.data(for: request)
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
    func fetchAllPosts() async throws -> [Post] {
        let endpoint = "\(baseURL)/posts"
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
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PostAPIError.invalidResponse
            }
            
            print("📡 ステータスコード: \(httpResponse.statusCode)")
            
            // レスポンスボディをデバッグ出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON: \(jsonString)")
            }
            
            if httpResponse.statusCode == 200 {
                // デバッグ用：レスポンスの詳細を確認
                debugJSONResponse(data, context: "fetchAllPosts")
                
                // APIHelperを使用してデコード
                let decoder = APIHelper.makeDecoder()
                
                do {
                    let posts = try decoder.decode([Post].self, from: data)
                    print("✅ デコード成功: \(posts.count)件の投稿")
                    
                    // 画像データの確認
                    for (index, post) in posts.enumerated() {
                        if let images = post.images, !images.isEmpty {
                            print("📸 投稿\(index + 1): \(images.count)枚の画像")
                            for (imageIndex, image) in images.enumerated() {
                                print("  画像\(imageIndex + 1): \(image.imageUrl)")
                            }
                        } else {
                            print("📸 投稿\(index + 1): 画像なし")
                        }
                    }
                    
                    return posts
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("🔑 キーが見つかりません: \(key.stringValue) at \(context.codingPath)")
                        case .typeMismatch(let type, let context):
                            print("📊 型の不一致: \(type) at \(context.codingPath)")
                        case .valueNotFound(let type, let context):
                            print("⚠️ 値が見つかりません: \(type) at \(context.codingPath)")
                        case .dataCorrupted(let context):
                            print("🔄 データ破損: \(context.debugDescription) at \(context.codingPath)")
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
    func fetchUserPosts(userId: Int) async throws -> [Post] {
        let endpoint = "\(baseURL)/users/\(userId)/posts"
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
            let (data, response) = try await APISession.shared.session.data(for: request)
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
    
    // 投稿を更新する
    func updatePost(postId: Int, content: String, shopId: Int? = nil, tags: [String] = []) async throws -> Post {
        let endpoint = "\(baseURL)/posts/\(postId)"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw PostAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
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
            "content": content
        ]
        
        // お店IDがある場合は追加
        if let shopId = shopId {
            body["shop_id"] = shopId
        }
        
        // タグがある場合は追加
        if !tags.isEmpty {
            body["tags"] = tags
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📡 PUT リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        print("📡 ボディ: \(body)")
        
        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
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
                    return try decoder.decode(Post.self, from: data)
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw PostAPIError.decodingError(error)
                }
            } else if httpResponse.statusCode == 403 {
                throw PostAPIError.apiError(403, "この投稿を編集する権限がありません")
            } else if httpResponse.statusCode == 404 {
                throw PostAPIError.apiError(404, "投稿が見つかりません")
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
    
    // 投稿を削除する
    func deletePost(postId: Int) async throws {
        let endpoint = "\(baseURL)/posts/\(postId)"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw PostAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ 認証トークンがありません")
        }
        
        print("📡 DELETE リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PostAPIError.invalidResponse
            }
            
            print("📡 ステータスコード: \(httpResponse.statusCode)")
            
            // レスポンスボディをデバッグ出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON: \(jsonString)")
            }
            
            if httpResponse.statusCode == 200 {
                print("✅ 投稿削除成功")
            } else if httpResponse.statusCode == 403 {
                throw PostAPIError.apiError(403, "この投稿を削除する権限がありません")
            } else if httpResponse.statusCode == 404 {
                throw PostAPIError.apiError(404, "投稿が見つかりません")
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
    
    // 投稿詳細を取得する
    func fetchPost(postId: Int) async throws -> Post {
        let endpoint = "\(baseURL)/posts/\(postId)"
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
            let (data, response) = try await APISession.shared.session.data(for: request)
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
                    return try decoder.decode(Post.self, from: data)
                } catch {
                    print("🚨 デコードエラー: \(error)")
                    throw PostAPIError.decodingError(error)
                }
            } else if httpResponse.statusCode == 404 {
                throw PostAPIError.apiError(404, "投稿が見つかりません")
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
