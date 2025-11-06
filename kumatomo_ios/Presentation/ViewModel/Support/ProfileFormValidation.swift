import Foundation
import UIKit

enum ValidationResult: Equatable {
    case valid
    case invalid(message: String)

    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }

    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

struct ProfileFormValidation {

    static func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return .invalid(message: "名前を入力してください")
        }

        if trimmedName.count < 1 {
            return .invalid(message: "名前は1文字以上で入力してください")
        }

        if trimmedName.count > 50 {
            return .invalid(message: "名前は50文字以内で入力してください")
        }

        return .valid
    }

    static func validateUsername(_ username: String) -> ValidationResult {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedUsername.isEmpty {
            return .invalid(message: "ユーザーネームを入力してください")
        }

        if trimmedUsername.count < 6 {
            return .invalid(message: "ユーザーネームは6文字以上で入力してください")
        }

        if trimmedUsername.count > 15 {
            return .invalid(message: "ユーザーネームは15文字以内で入力してください")
        }

        let usernameRegex = "^[a-zA-Z0-9]+$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        if !usernamePredicate.evaluate(with: trimmedUsername) {
            return .invalid(message: "ユーザーネームは英数字のみ使用できます")
        }

        return .valid
    }

    static func validateEmail(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            return .invalid(message: "メールアドレスを入力してください")
        }

        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: trimmedEmail) {
            return .invalid(message: "有効なメールアドレスを入力してください")
        }

        if trimmedEmail.count > 255 {
            return .invalid(message: "メールアドレスは255文字以内で入力してください")
        }

        return .valid
    }

    static func validateBio(_ bio: String) -> ValidationResult {
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedBio.count > 500 {
            return .invalid(message: "自己紹介は500文字以内で入力してください")
        }

        return .valid
    }

    static func validateLocation(_ location: String) -> ValidationResult {
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedLocation.count > 100 {
            return .invalid(message: "出身地は100文字以内で入力してください")
        }

        return .valid
    }

    static func validateBirthday(_ birthday: Date?) -> ValidationResult {
        guard let birthday = birthday else {
            return .valid
        }

        let calendar = Calendar.current
        let now = Date()

        if birthday > now {
            return .invalid(message: "誕生日は未来の日付にできません")
        }

        let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
        if let age = ageComponents.year, age > 150 {
            return .invalid(message: "有効な誕生日を入力してください")
        }

        return .valid
    }

    static func validateCompleteProfile(
        name: String,
        username: String,
        email: String,
        bio: String,
        location: String,
        birthday: Date?
    ) -> [String] {
        var errors: [String] = []

        let nameResult = validateName(name)
        if !nameResult.isValid, let error = nameResult.errorMessage {
            errors.append(error)
        }

        let usernameResult = validateUsername(username)
        if !usernameResult.isValid, let error = usernameResult.errorMessage {
            errors.append(error)
        }

        let emailResult = validateEmail(email)
        if !emailResult.isValid, let error = emailResult.errorMessage {
            errors.append(error)
        }

        let bioResult = validateBio(bio)
        if !bioResult.isValid, let error = bioResult.errorMessage {
            errors.append(error)
        }

        let locationResult = validateLocation(location)
        if !locationResult.isValid, let error = locationResult.errorMessage {
            errors.append(error)
        }

        let birthdayResult = validateBirthday(birthday)
        if !birthdayResult.isValid, let error = birthdayResult.errorMessage {
            errors.append(error)
        }

        return errors
    }
}
