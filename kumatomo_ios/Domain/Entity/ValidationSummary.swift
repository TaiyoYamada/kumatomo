import Foundation

// MARK: - ValidationSummary

/// プロフィールフォームのバリデーション結果サマリー
/// 全フィールドのバリデーション状態を集約して管理する
struct ValidationSummary {
    let emailValidation: ValidationResult
    let nameValidation: ValidationResult
    let usernameValidation: ValidationResult
    let bioValidation: ValidationResult
    let locationValidation: ValidationResult
    let birthdayValidation: ValidationResult
    let isUsernameAvailable: Bool?
    let isValidatingUsername: Bool
    let isFormValid: Bool
    let hasUnsavedChanges: Bool

    var allErrors: [String] {
        var errors: [String] = []

        if !emailValidation.isValid, let error = emailValidation.errorMessage {
            errors.append(error)
        }
        if !nameValidation.isValid, let error = nameValidation.errorMessage {
            errors.append(error)
        }
        if !usernameValidation.isValid, let error = usernameValidation.errorMessage {
            errors.append(error)
        }
        if !bioValidation.isValid, let error = bioValidation.errorMessage {
            errors.append(error)
        }
        if !locationValidation.isValid, let error = locationValidation.errorMessage {
            errors.append(error)
        }
        if !birthdayValidation.isValid, let error = birthdayValidation.errorMessage {
            errors.append(error)
        }

        if let isAvailable = isUsernameAvailable, !isAvailable {
            errors.append("ユーザーネームが利用できません")
        }

        return errors
    }

    var validFieldCount: Int {
        var count = 0
        if emailValidation.isValid { count += 1 }
        if nameValidation.isValid { count += 1 }
        if usernameValidation.isValid { count += 1 }
        if bioValidation.isValid { count += 1 }
        if locationValidation.isValid { count += 1 }
        if birthdayValidation.isValid { count += 1 }
        return count
    }

    var totalFieldCount: Int { return 7 }

    var completionPercentage: Double {
        return Double(validFieldCount) / Double(totalFieldCount)
    }
}
