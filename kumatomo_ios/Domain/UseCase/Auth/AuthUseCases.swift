import Foundation

// MARK: - SignInUseCase

protocol SignInUseCase { @MainActor func execute(email: String, password: String) async throws }

// MARK: - SignOutUseCase

protocol SignOutUseCase { @MainActor func execute() async throws }

// MARK: - CreateUserUseCase

protocol CreateUserUseCase { @MainActor func execute(email: String, password: String) async throws }

// MARK: - UpdateUserUseCase

protocol UpdateUserUseCase { @MainActor func execute(
    name: String?,
    profileImageURL: String?,
    bio: String?,
    location: String?,
    birthday: Date?,
    hasCompletedSetup: Bool?
) async throws }

// MARK: - SignInUseCaseImpl

final class SignInUseCaseImpl: SignInUseCase {
    private let repository: AuthRepository
    init(repository: AuthRepository) { self.repository = repository }
    @MainActor func execute(email: String, password: String) async throws { try await repository.signIn(
        withEmail: email,
        password: password
    ) }
}

// MARK: - SignOutUseCaseImpl

final class SignOutUseCaseImpl: SignOutUseCase {
    private let repository: AuthRepository
    init(repository: AuthRepository) { self.repository = repository }
    @MainActor func execute() async throws { try await repository.signOut() }
}

// MARK: - CreateUserUseCaseImpl

final class CreateUserUseCaseImpl: CreateUserUseCase {
    private let repository: AuthRepository
    init(repository: AuthRepository) { self.repository = repository }
    @MainActor func execute(email: String, password: String) async throws { try await repository.createUser(
        withEmail: email,
        password: password
    ) }
}

// MARK: - UpdateUserUseCaseImpl

final class UpdateUserUseCaseImpl: UpdateUserUseCase {
    private let repository: AuthRepository
    init(repository: AuthRepository) { self.repository = repository }
    @MainActor func execute(
        name: String?,
        profileImageURL: String?,
        bio: String?,
        location: String?,
        birthday: Date?,
        hasCompletedSetup: Bool?
    ) async throws {
        try await repository.updateUser(
            withName: name,
            profileImageURL: profileImageURL,
            bio: bio,
            location: location,
            birthday: birthday,
            hasCompletedSetup: hasCompletedSetup
        )
    }
}
