import Foundation

// MARK: - ValidateProfileUseCase

/// プロフィールバリデーションを行うUseCase
struct ValidateProfileUseCase: ValidateProfileUseCaseProtocol {

    // MARK: - Constants

    private enum Constants {
        static let minNameLength = 1
        static let maxNameLength = 30
        static let minUsernameLength = 6
        static let maxUsernameLength = 15
        static let maxEmailLength = 255
        static let maxBioLength = 500
        static let maxLocationLength = 100
        static let maxAge = 150
    }

    // MARK: - ValidateProfileUseCaseProtocol

    func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return .invalid(message: "名前を入力してください")
        }

        if trimmedName.count < Constants.minNameLength {
            return .invalid(message: "名前は\(Constants.minNameLength)文字以上で入力してください")
        }

        if trimmedName.count > Constants.maxNameLength {
            return .invalid(message: "名前は\(Constants.maxNameLength)文字以内で入力してください")
        }

        return .valid
    }

    func validateUsername(_ username: String) -> ValidationResult {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedUsername.isEmpty {
            return .invalid(message: "ユーザーネームを入力してください")
        }

        if trimmedUsername.count < Constants.minUsernameLength {
            return .invalid(message: "ユーザーネームは\(Constants.minUsernameLength)文字以上で入力してください")
        }

        if trimmedUsername.count > Constants.maxUsernameLength {
            return .invalid(message: "ユーザーネームは\(Constants.maxUsernameLength)文字以内で入力してください")
        }

        let usernameRegex = "^[a-zA-Z0-9]+$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        if !usernamePredicate.evaluate(with: trimmedUsername) {
            return .invalid(message: "ユーザーネームは英数字のみ使用できます")
        }

        return .valid
    }

    func validateEmail(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            return .invalid(message: "メールアドレスを入力してください")
        }

        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: trimmedEmail) {
            return .invalid(message: "有効なメールアドレスを入力してください")
        }

        if trimmedEmail.count > Constants.maxEmailLength {
            return .invalid(message: "メールアドレスは\(Constants.maxEmailLength)文字以内で入力してください")
        }

        return .valid
    }

    func validateBio(_ bio: String) -> ValidationResult {
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedBio.count > Constants.maxBioLength {
            return .invalid(message: "自己紹介は\(Constants.maxBioLength)文字以内で入力してください")
        }

        return .valid
    }

    func validateLocation(_ location: String) -> ValidationResult {
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedLocation.count > Constants.maxLocationLength {
            return .invalid(message: "出身地は\(Constants.maxLocationLength)文字以内で入力してください")
        }

        return .valid
    }

    func validateBirthday(_ birthday: Date?) -> ValidationResult {
        guard let birthday else {
            return .valid
        }

        let calendar = Calendar.current
        let now = Date()

        if birthday > now {
            return .invalid(message: "誕生日は未来の日付にできません")
        }

        let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
        if let age = ageComponents.year, age > Constants.maxAge {
            return .invalid(message: "有効な誕生日を入力してください")
        }

        return .valid
    }

    func validateCompleteProfile(
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
