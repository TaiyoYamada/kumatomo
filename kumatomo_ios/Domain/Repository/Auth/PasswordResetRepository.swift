import Foundation
import Mockable

/// パスワードリセット機能のリポジトリプロトコル
@Mockable
protocol PasswordResetRepository {
    /// パスワードリセット用のOTPコードをメールで送信
    /// - Parameter email: 登録済みメールアドレス
    func sendResetCode(email: String) async throws

    /// OTPコードを検証してリセットトークンを取得
    /// - Parameters:
    ///   - email: メールアドレス
    ///   - code: 6桁のOTPコード
    /// - Returns: リセットトークン
    func verifyResetCode(email: String, code: String) async throws -> String

    /// 新しいパスワードを設定
    /// - Parameters:
    ///   - token: リセットトークン
    ///   - newPassword: 新しいパスワード
    ///   - confirmPassword: パスワード確認
    func resetPassword(token: String, newPassword: String, confirmPassword: String) async throws
}
