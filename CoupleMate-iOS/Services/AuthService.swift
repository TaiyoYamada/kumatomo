import Foundation
import Combine

// 認証トークンを管理するクラス
class AuthTokenManager {
    static let shared = AuthTokenManager()
    
    private let tokenKey = "auth_token"
    
    var token: String? {
        get {
            return UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: tokenKey)
        }
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    // リクエストにBearer認証トークンを追加
    func authorizedRequest(_ request: inout URLRequest) {
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

}

class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?

    static let shared = AuthService()
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://10.33.2.4:8000/api"


    init() {
        // アプリ起動時にトークンが存在するか確認
        if AuthTokenManager.shared.token != nil {
            self.isAuthenticated = true
            Task { [weak self] in
                do {
                    try await self?.fetchCurrentUser()
                } catch {
                    print("⚠️ 自動ログイン失敗: \(error.localizedDescription)")
                    AuthTokenManager.shared.clearToken()
                    DispatchQueue.main.async {
                        self?.isAuthenticated = false
                    }
                }
            }
        }
    }


    @MainActor
    func signIn(withEmail email: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let credentials = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(credentials)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            // エラーレスポンスの解析
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(message: errorResponse.message)
            }
            throw AuthError.invalidCredentials
        }
        
        // レスポンスからトークンを抽出
        guard let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
            throw AuthError.invalidResponse
        }
        
        // トークンを保存
        AuthTokenManager.shared.token = authResponse.access_token
        
        self.isAuthenticated = true
        
        // ユーザー情報の取得
        try await fetchCurrentUser()
    }

    @MainActor
    func createUser(withEmail email: String, password: String, name: String, birthDate: Date?) async throws {
        let url = URL(string: "\(baseURL)/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ユーザー登録に必要なデータを準備
        var registrationData: [String: Any] = [
            "email": email,
            "password": password,
        ]
        
        if let birthDate = birthDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            registrationData["birth_date"] = formatter.string(from: birthDate)
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: registrationData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            // エラーレスポンスの解析
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(message: errorResponse.message)
            }
            throw AuthError.registrationFailed
        }
        
        // レスポンスからトークンを抽出
        guard let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
            throw AuthError.invalidResponse
        }
        
        // トークンを保存
        AuthTokenManager.shared.token = authResponse.access_token
        
        self.isAuthenticated = true
        
        // ユーザー情報の取得
        try await fetchCurrentUser()
    }

    @MainActor
    func signOut() async throws {
        guard AuthTokenManager.shared.token != nil else {
            // トークンがなければ何もしない
            self.isAuthenticated = false
            self.currentUser = nil
            return
        }
        
        let url = URL(string: "\(baseURL)/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 認証トークンをヘッダーに追加
        AuthTokenManager.shared.authorizedRequest(&request)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
                throw AuthError.logoutFailed
            }
        } catch {
            print("⚠️ ログアウト中にエラー発生: \(error.localizedDescription)")
            // エラーが発生してもトークンは削除する
        }
        
        // トークンをクリア
        AuthTokenManager.shared.clearToken()
        
        self.isAuthenticated = false
        self.currentUser = nil
    }

    @MainActor
    func fetchCurrentUser() async throws {
        guard AuthTokenManager.shared.token != nil else {
            print("⚠️ トークンが存在しません")
            throw AuthError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        AuthTokenManager.shared.authorizedRequest(&request)

        print("📡 リクエスト先URL:", request.url?.absoluteString ?? "nil")
        print("📡 Authorizationヘッダー:", request.allHTTPHeaderFields?["Authorization"] ?? "なし")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 ステータスコード:", httpResponse.statusCode)
            } else {
                print("⚠️ HTTPレスポンスではありません")
            }

            // レスポンスデータを一度文字列で出力（デバッグ用）
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON:", jsonString)
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            if httpResponse.statusCode == 401 {
                AuthTokenManager.shared.clearToken()
                self.isAuthenticated = false
                print("⚠️ 認証エラー（401）")
                throw AuthError.unauthorized
            }

            if httpResponse.statusCode != 200 {
                print("⚠️ ユーザー取得失敗（ステータス: \(httpResponse.statusCode)）")
                throw AuthError.fetchUserFailed
            }

            self.currentUser = try JSONDecoder().decode(UserResponse.self, from: data).data

            print("✅ ユーザー情報取得成功: \(self.currentUser?.email ?? "不明")")

        } catch {
            print("🚨 通信エラー: \(error.localizedDescription)")
            throw error
        }
    }

    
    @MainActor
    func updateProfileImage(withImageUrl url: String) async throws {
        guard AuthTokenManager.shared.token != nil else {
            throw AuthError.unauthorized
        }
        
        guard var user = currentUser else {
            throw AuthError.userNotFound
        }
        
        user.profileImageURL = url
        
        let apiUrl = URL(string: "\(baseURL)/user/profile")!
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 認証トークンをヘッダーに追加
        AuthTokenManager.shared.authorizedRequest(&request)
        
        // プロフィール更新データ
        let profileData = ["profile_image_url": url]
        request.httpBody = try JSONEncoder().encode(profileData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            // 認証エラー
            AuthTokenManager.shared.clearToken()
            self.isAuthenticated = false
            throw AuthError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(message: errorResponse.message)
            }
            throw AuthError.updateProfileFailed
        }
        
        // 成功したら最新のユーザー情報を取得
        try await fetchCurrentUser()
    }
}

// エラー定義
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case invalidResponse
    case registrationFailed
    case unauthorized
    case fetchUserFailed
    case logoutFailed
    case updateProfileFailed
    case userNotFound
    case serverError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "メールアドレスまたはパスワードが正しくありません"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .registrationFailed:
            return "ユーザー登録に失敗しました"
        case .unauthorized:
            return "認証が必要です"
        case .fetchUserFailed:
            return "ユーザー情報の取得に失敗しました"
        case .logoutFailed:
            return "ログアウトに失敗しました"
        case .updateProfileFailed:
            return "プロフィールの更新に失敗しました"
        case .userNotFound:
            return "ユーザー情報が見つかりません"
        case .serverError(let message):
            return message
        }
    }
}

// レスポンス型定義
struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
}

struct ErrorResponse: Codable {
    let message: String
    let errors: [String: [String]]?
}
