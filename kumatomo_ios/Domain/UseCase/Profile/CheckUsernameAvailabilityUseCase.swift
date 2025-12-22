import Foundation

// MARK: - CheckUsernameAvailabilityUseCase

/// ユーザーネームの利用可能性をチェックするUseCase
struct CheckUsernameAvailabilityUseCase: CheckUsernameAvailabilityUseCaseProtocol {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(username: String) async throws -> Bool {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty else {
            return false
        }

        return try await userRepository.checkUsernameAvailability(trimmedUsername)
    }
}
