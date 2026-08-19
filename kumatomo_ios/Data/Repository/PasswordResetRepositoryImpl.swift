import Foundation

// MARK: - PasswordResetRepositoryImpl

/// パスワードリセットリポジトリの実装
final class PasswordResetRepositoryImpl: PasswordResetRepository {

    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }

    func sendResetCode(email: String) async throws {
        let _: ForgotPasswordResponse = try await apiClient.post(
            PasswordResetEndpoint.forgotPassword(email: email)
        )
    }

    func verifyResetCode(email: String, code: String) async throws -> String {
        let response: VerifyCodeResponse = try await apiClient.post(
            PasswordResetEndpoint.verifyCode(email: email, code: code)
        )
        return response.resetToken
    }

    func resetPassword(token: String, newPassword: String, confirmPassword: String) async throws {
        let _: ResetPasswordResponse = try await apiClient.post(
            PasswordResetEndpoint.resetPassword(
                token: token,
                password: newPassword,
                passwordConfirmation: confirmPassword
            )
        )
    }
}

// MARK: - ForgotPasswordResponse

private struct ForgotPasswordResponse: Decodable {
    let message: String
    let expiresInMinutes: Int?
}

// MARK: - VerifyCodeResponse

private struct VerifyCodeResponse: Decodable {
    let message: String
    let resetToken: String
}

// MARK: - ResetPasswordResponse

private struct ResetPasswordResponse: Decodable {
    let message: String
}
