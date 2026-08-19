import Foundation

// MARK: - SendResetCodeUseCaseProtocol

/// パスワードリセットコード送信のユースケースプロトコル
protocol SendResetCodeUseCaseProtocol {
    func execute(email: String) async throws
}

// MARK: - SendResetCodeUseCase

/// パスワードリセットコード送信のユースケース実装
struct SendResetCodeUseCase: SendResetCodeUseCaseProtocol {
    private let repository: PasswordResetRepository

    init(repository: PasswordResetRepository) {
        self.repository = repository
    }

    func execute(email: String) async throws {
        try await repository.sendResetCode(email: email)
    }
}

// MARK: - VerifyResetCodeUseCaseProtocol

/// OTPコード検証のユースケースプロトコル
protocol VerifyResetCodeUseCaseProtocol {
    func execute(email: String, code: String) async throws -> String
}

// MARK: - VerifyResetCodeUseCase

/// OTPコード検証のユースケース実装
struct VerifyResetCodeUseCase: VerifyResetCodeUseCaseProtocol {
    private let repository: PasswordResetRepository

    init(repository: PasswordResetRepository) {
        self.repository = repository
    }

    func execute(email: String, code: String) async throws -> String {
        try await repository.verifyResetCode(email: email, code: code)
    }
}

// MARK: - ResetPasswordUseCaseProtocol

/// パスワードリセット実行のユースケースプロトコル
protocol ResetPasswordUseCaseProtocol {
    func execute(token: String, newPassword: String, confirmPassword: String) async throws
}

// MARK: - ResetPasswordUseCase

/// パスワードリセット実行のユースケース実装
struct ResetPasswordUseCase: ResetPasswordUseCaseProtocol {
    private let repository: PasswordResetRepository

    init(repository: PasswordResetRepository) {
        self.repository = repository
    }

    func execute(token: String, newPassword: String, confirmPassword: String) async throws {
        try await repository.resetPassword(
            token: token,
            newPassword: newPassword,
            confirmPassword: confirmPassword
        )
    }
}
