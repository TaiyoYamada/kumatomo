import Foundation

// MARK: - ValidateProfileUseCaseProtocol

/// プロフィールバリデーションを行うUseCaseのProtocol
protocol ValidateProfileUseCaseProtocol: Sendable {
    /// 名前のバリデーション
    func validateName(_ name: String) -> ValidationResult

    /// ユーザーネームのバリデーション（フォーマットのみ）
    func validateUsername(_ username: String) -> ValidationResult

    /// メールアドレスのバリデーション
    func validateEmail(_ email: String) -> ValidationResult

    /// 自己紹介のバリデーション
    func validateBio(_ bio: String) -> ValidationResult

    /// 出身地のバリデーション
    func validateLocation(_ location: String) -> ValidationResult

    /// 誕生日のバリデーション
    func validateBirthday(_ birthday: Date?) -> ValidationResult

    /// 全フィールドのバリデーション
    func validateCompleteProfile(
        name: String,
        username: String,
        email: String,
        bio: String,
        location: String,
        birthday: Date?
    ) -> [String]
}
