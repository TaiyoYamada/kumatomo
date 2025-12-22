import Foundation

// MARK: - UpdateProfileUseCase

/// プロフィール更新を行うUseCase
struct UpdateProfileUseCase: UpdateProfileUseCaseProtocol {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(user: User) async throws -> User {
        // バリデーション
        let validateUseCase = ValidateProfileUseCase()
        let errors = validateUseCase.validateCompleteProfile(
            name: user.name ?? "",
            username: user.username ?? "",
            email: user.email ?? "",
            bio: user.bio ?? "",
            location: user.location ?? "",
            birthday: parseBirthday(user.birthday)
        )

        if !errors.isEmpty {
            throw ProfileError.validationFailed(errors)
        }

        // リポジトリ経由で更新
        return try await userRepository.updateProfile(user)
    }

    private func parseBirthday(_ birthdayString: String?) -> Date? {
        guard let birthdayString, !birthdayString.isEmpty else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: birthdayString)
    }
}
