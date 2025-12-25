import Foundation
import Factory

// MARK: - PasswordResetFlowState

/// パスワードリセット画面のフロー状態
enum PasswordResetFlowState: Equatable {
    case enterEmail // メールアドレス入力
    case enterCode // OTPコード入力
    case enterNewPassword // 新パスワード入力
    case completed // 完了
}

// MARK: - PasswordResetViewModel

/// パスワードリセット用ViewModel
@MainActor
@Observable
final class PasswordResetViewModel {
    // MARK: - Properties

    var email = ""
    var code = ""
    var newPassword = ""
    var confirmPassword = ""

    var flowState: PasswordResetFlowState = .enterEmail
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    // リセットトークン（コード検証後に取得）
    private var resetToken: String?

    // MARK: - Dependencies

    @ObservationIgnored @Injected(\.sendResetCodeUseCase) private var sendResetCodeUseCase
    @ObservationIgnored @Injected(\.verifyResetCodeUseCase) private var verifyResetCodeUseCase
    @ObservationIgnored @Injected(\.resetPasswordUseCase) private var resetPasswordUseCase

    // MARK: - Public Methods

    /// パスワードリセットコードを送信
    func sendResetCode() async {
        guard validateEmail() else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await sendResetCodeUseCase.execute(email: email)
            flowState = .enterCode
            successMessage = "認証コードをメールで送信しました"
        } catch {
            errorMessage = parseError(error)
        }

        isLoading = false
    }

    /// OTPコードを検証
    func verifyCode() async {
        guard validateCode() else { return }

        isLoading = true
        errorMessage = nil

        do {
            resetToken = try await verifyResetCodeUseCase.execute(email: email, code: code)
            flowState = .enterNewPassword
            successMessage = nil
        } catch {
            errorMessage = parseError(error)
        }

        isLoading = false
    }

    /// 新しいパスワードを設定
    func resetPassword() async {
        guard validateNewPassword() else { return }
        guard let token = resetToken else {
            errorMessage = "リセットトークンが見つかりません。最初からやり直してください"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await resetPasswordUseCase.execute(
                token: token,
                newPassword: newPassword,
                confirmPassword: confirmPassword
            )
            flowState = .completed
            successMessage = "パスワードが正常にリセットされました"
        } catch {
            errorMessage = parseError(error)
        }

        isLoading = false
    }

    /// コードを再送信
    func resendCode() async {
        isLoading = true
        errorMessage = nil

        do {
            try await sendResetCodeUseCase.execute(email: email)
            successMessage = "認証コードを再送信しました"
        } catch {
            errorMessage = parseError(error)
        }

        isLoading = false
    }

    /// フローをリセット
    func reset() {
        email = ""
        code = ""
        newPassword = ""
        confirmPassword = ""
        flowState = .enterEmail
        resetToken = nil
        errorMessage = nil
        successMessage = nil
    }

    // MARK: - Private Methods

    private func validateEmail() -> Bool {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "メールアドレスを入力してください"
            return false
        }
        if !email.contains("@") {
            errorMessage = "有効なメールアドレスを入力してください"
            return false
        }
        return true
    }

    private func validateCode() -> Bool {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCode.isEmpty {
            errorMessage = "認証コードを入力してください"
            return false
        }
        if trimmedCode.count != 6 {
            errorMessage = "認証コードは6桁で入力してください"
            return false
        }
        return true
    }

    private func validateNewPassword() -> Bool {
        if newPassword.isEmpty {
            errorMessage = "新しいパスワードを入力してください"
            return false
        }
        if newPassword.count < 6 {
            errorMessage = "パスワードは6文字以上で入力してください"
            return false
        }
        if newPassword != confirmPassword {
            errorMessage = "パスワードが一致しません"
            return false
        }
        return true
    }

    private func parseError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.localizedDescription
        }
        return error.localizedDescription
    }
}
