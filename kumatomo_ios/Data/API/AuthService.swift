import Foundation
import Combine

// MARK: - AuthService

class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?

    static let shared = AuthService()

    private var cancellables = Set<AnyCancellable>()
    private let baseURL = APIConfig.shared.baseURLString

    init() {
        print("🚀 AuthService init called")

        if AuthTokenManager.shared.token != nil {
            isAuthenticated = true
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await fetchCurrentUser()
                    await MainActor.run {
                        print("✅ 自動ログイン成功: \(self.currentUser?.email ?? "不明")")
                    }
                } catch {
                    print("⚠️ 自動ログイン失敗: \(error.localizedDescription)")
                    AuthTokenManager.shared.clearToken()
                    await MainActor.run {
                        self.isAuthenticated = false
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

        let (data, response) = try await APISession.shared.session.data(for: request)

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

        isAuthenticated = true

        // ユーザー情報の取得
        try await fetchCurrentUser()
    }

    @MainActor
    func signOut() async throws {
        guard AuthTokenManager.shared.token != nil else {
            // トークンがなければ何もしない
            isAuthenticated = false
            currentUser = nil
            return
        }

        let url = URL(string: "\(baseURL)/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // 認証トークンをヘッダーに追加
        AuthTokenManager.shared.authorizedRequest(&request)

        do {
            let (_, response) = try await APISession.shared.session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            if httpResponse.statusCode != 200, httpResponse.statusCode != 204 {
                throw AuthError.logoutFailed
            }
        } catch {
            print("⚠️ ログアウト中にエラー発生: \(error.localizedDescription)")
            // エラーが発生してもトークンは削除する
        }

        // トークンをクリア
        AuthTokenManager.shared.clearToken()

        isAuthenticated = false
        currentUser = nil
    }

    @MainActor
    func refreshToken() async throws {
        guard AuthTokenManager.shared.token != nil else {
            throw AuthError.unauthorized
        }
        try await fetchCurrentUser()
    }

    @MainActor
    func createUser(withEmail email: String, password: String) async throws {
        print("🚀 ユーザー登録開始")

        let url = URL(string: "\(baseURL)/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var registrationData: [String: Any] = [
            "email": email,
            "password": password,
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: registrationData)
            print("📦 リクエストボディ生成成功: \(registrationData)")
        } catch {
            print("❌ JSONシリアライズ失敗: \(error.localizedDescription)")
            throw error
        }

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            print("📡 サーバーからレスポンスを受信")

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ HTTPレスポンスの取得に失敗")
                throw URLError(.badServerResponse)
            }

            print("📡 ステータスコード: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200, httpResponse.statusCode != 201 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    print("❌ サーバーエラー: \(errorResponse.message)")
                    throw AuthError.serverError(message: errorResponse.message)
                }
                print("❌ サーバーからの登録失敗レスポンス")
                throw AuthError.registrationFailed
            }

            guard let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
                print("❌ レスポンスのデコードに失敗（AuthResponse）")
                throw AuthError.invalidResponse
            }

            print("✅ トークン取得成功: \(authResponse.access_token)")
            AuthTokenManager.shared.token = authResponse.access_token
            isAuthenticated = true

            print("📥 ユーザー情報の取得を開始")
            try await fetchCurrentUser()
            print("✅ ユーザー情報の取得成功: \(currentUser?.email ?? "不明")")

        } catch {
            print("❌ ユーザー登録処理中にエラー発生: \(error.localizedDescription)")
            throw error
        }
    }

    @MainActor
    func updateUser(
        withName name: String?,
        profileImageURL: String?,
        bio: String?,
        location: String?,
        birthday: Date?,
        hasCompletedSetup: Bool?
    ) async throws {
        guard AuthTokenManager.shared.token != nil else {
            throw AuthError.unauthorized
        }

        let url = URL(string: "\(baseURL)/user/update")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 認証トークンをヘッダーに追加
        AuthTokenManager.shared.authorizedRequest(&request)

        var updateData: [String: Any] = [:]

        if let name {
            updateData["name"] = name
        }

        if let profileImageURL {
            updateData["profileImageURL"] = profileImageURL
        }

        if let bio {
            updateData["bio"] = bio
        }

        if let location {
            updateData["location"] = location
        }

        if let birthday {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            updateData["birthday"] = formatter.string(from: birthday)
        }

        if let hasCompletedSetup {
            updateData["hasCompletedSetup"] = hasCompletedSetup
            print("🔄 hasCompletedSetup送信: \(hasCompletedSetup)")
        }

        print("🔄 送信データ: \(updateData)")
        request.httpBody = try JSONSerialization.data(withJSONObject: updateData)

        let (data, response) = try await APISession.shared.session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            // 認証エラー
            isAuthenticated = false
            throw AuthError.unauthorized
        }

        if httpResponse.statusCode != 200 {
            // エラーレスポンスの解析
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(message: errorResponse.message)
            }
            throw AuthError.updateProfileFailed
        }

        // 成功したら最新のユーザー情報を取得
        try await fetchCurrentUser()
        print("🔄 ユーザー更新後のhasCompletedSetup: \(currentUser?.hasCompletedSetup ?? false)")
    }

    @MainActor
    func fetchCurrentUser() async throws {
        guard let token = AuthTokenManager.shared.token, !token.isEmpty else {
            print("⚠️ トークンが存在しないか空です")
            throw AuthError.unauthorized
        }

        // トークンの内容を確認（デバッグ用）
        print("🔑 現在のトークン: \(token)")

        let url = URL(string: "\(baseURL)/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        AuthTokenManager.shared.authorizedRequest(&request)

        print("📡 リクエスト先URL:", request.url?.absoluteString ?? "nil")
        print("📡 Authorizationヘッダー:", request.allHTTPHeaderFields?["Authorization"] ?? "なし")
        print("📡 全ヘッダー:", request.allHTTPHeaderFields ?? [:])

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 ステータスコード:", httpResponse.statusCode)
                print("📡 レスポンスヘッダー:", httpResponse.allHeaderFields)
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
                print("⚠️ 認証エラー（401）- トークンが無効か期限切れの可能性があります")
                AuthTokenManager.shared.clearToken()
                isAuthenticated = false
                throw AuthError.unauthorized
            }

            if httpResponse.statusCode != 200 {
                print("⚠️ ユーザー取得失敗（ステータス: \(httpResponse.statusCode)）")
                throw AuthError.fetchUserFailed
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            do {
                let userResponse = try decoder.decode(UserResponse.self, from: data)
                currentUser = userResponse.data
                isAuthenticated = true
                print(
                    "✅ ユーザー情報取得成功: \(currentUser?.email ?? "不明"), hasCompletedSetup: \(currentUser?.hasCompletedSetup ?? false)"
                )
            } catch let decodingError {
                print("🚨 ユーザーデータのデコードに失敗: \(decodingError)")
                // エラーの詳細を出力
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 デコードに失敗したJSON: \(jsonString)")
                }
                throw decodingError // エラーを再スローして呼び出し元に伝える
            }
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

        let profileData = ["profileImageURL": url]
        request.httpBody = try JSONEncoder().encode(profileData)

        let (data, response) = try await APISession.shared.session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            // 認証エラー
            isAuthenticated = false
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

// MARK: - AuthResponse

// レスポンス型定義
struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
}

// MARK: - ErrorResponse

struct ErrorResponse: Codable {
    let message: String
    let errors: [String: [String]]?
}
