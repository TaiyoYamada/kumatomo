import Combine
import Foundation

// MARK: - AuthService

final class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?

    static let shared = AuthService()

    private let client = APIClient.shared
    private let logger = AppLogger.auth
    private var cancellables = Set<AnyCancellable>()

    init() {
        logger.debug("AuthService initialized")
        attemptAutoLogin()
    }

    private func attemptAutoLogin() {
        guard AuthTokenManager.shared.token != nil else { return }
        isAuthenticated = true
        Task { [weak self] in
            do {
                try await self?.fetchCurrentUser()
                self?.logger.info("自動ログイン成功")
            } catch {
                self?.logger.warning("自動ログイン失敗: \(error.localizedDescription)")
                AuthTokenManager.shared.clearToken()
                await MainActor.run { self?.isAuthenticated = false }
            }
        }
    }

    // MARK: - Authentication

    @MainActor
    func signIn(withEmail email: String, password: String) async throws {
        let response: AuthResponse = try await client.post(AuthEndpoint.login(email: email, password: password))

        AuthTokenManager.shared.token = response.accessToken
        isAuthenticated = true

        try await fetchCurrentUser()
    }

    @MainActor
    func signOut() async throws {
        guard AuthTokenManager.shared.token != nil else {
            isAuthenticated = false
            currentUser = nil
            return
        }

        do {
            try await client.requestVoid(AuthEndpoint.logout)
        } catch {
            logger.warning("ログアウト中にエラー発生: \(error.localizedDescription)")
        }

        AuthTokenManager.shared.clearToken()
        isAuthenticated = false
        currentUser = nil
    }

    @MainActor
    func createUser(withEmail email: String, password: String, passwordConfirmation: String) async throws {
        logger.debug("ユーザー登録開始")

        let response: AuthResponse = try await client.post(AuthEndpoint.register(
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation
        ))

        logger.info("トークン取得成功")
        AuthTokenManager.shared.token = response.accessToken
        isAuthenticated = true

        try await fetchCurrentUser()
        logger.info("ユーザー情報の取得成功: \(currentUser?.email ?? "不明")")
    }

    @MainActor
    func refreshToken() async throws {
        guard AuthTokenManager.shared.token != nil else {
            throw AuthError.unauthorized
        }
        try await fetchCurrentUser()
    }

    // MARK: - User Profile

    @MainActor
    func fetchCurrentUser() async throws {
        guard let token = AuthTokenManager.shared.token, !token.isEmpty else {
            throw AuthError.unauthorized
        }

        logger.debug("現在のトークンでユーザー情報を取得")

        let response: UserResponse = try await client.get(AuthEndpoint.currentUser)
        currentUser = response.data
        isAuthenticated = true

        logger.info("ユーザー情報取得成功: \(currentUser?.email ?? "不明")")
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

        var updateData: [String: Any] = [:]
        if let name { updateData["name"] = name }
        if let profileImageURL { updateData["profileImageURL"] = profileImageURL }
        if let bio { updateData["bio"] = bio }
        if let location { updateData["location"] = location }
        if let birthday {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            updateData["birthday"] = formatter.string(from: birthday)
        }
        if let hasCompletedSetup { updateData["hasCompletedSetup"] = hasCompletedSetup }

        logger.debug("ユーザー更新データ: \(updateData)")

        let _: UserResponse = try await client.put(AuthEndpoint.updateUser(data: updateData))
        try await fetchCurrentUser()

        logger.info("ユーザー更新完了: hasCompletedSetup=\(currentUser?.hasCompletedSetup ?? false)")
    }

    @MainActor
    func updateProfileImage(withImageUrl url: String) async throws {
        try await updateUser(
            withName: nil,
            profileImageURL: url,
            bio: nil,
            location: nil,
            birthday: nil,
            hasCompletedSetup: nil
        )
    }
}

// MARK: - AuthResponse

struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
}

// MARK: - ErrorResponse

struct ErrorResponse: Codable {
    let message: String
    let errors: [String: [String]]?
}
