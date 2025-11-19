import Foundation

protocol SignInUseCase { @MainActor func execute(email: String, password: String) async throws }
protocol SignOutUseCase { @MainActor func execute() async throws }
protocol CreateUserUseCase { @MainActor func execute(email: String, password: String) async throws }
protocol UpdateUserUseCase { @MainActor func execute(name: String?, profileImageURL: String?, bio: String?, location: String?, birthday: Date?, hasCompletedSetup: Bool?) async throws }

final class SignInUseCaseImpl: SignInUseCase {
    private let repository: AuthRepository
    init(repository: AuthRepository) { self.repository = repository }
    @MainActor func execute(email: String, password: String) async throws { try await repository.signIn(withEmail: email, password: password) }
}

final class SignOutUseCaseImpl: SignOutUseCase {
    private let repository: AuthRepository
    init(repository: AuthRepository) { self.repository = repository }
    @MainActor func execute() async throws { try await repository.signOut() }
}

final class CreateUserUseCaseImpl: CreateUserUseCase {
    private let repository: AuthRepository
    init(repository: AuthRepository) { self.repository = repository }
    @MainActor func execute(email: String, password: String) async throws { try await repository.createUser(withEmail: email, password: password) }
}

final class UpdateUserUseCaseImpl: UpdateUserUseCase {
    private let repository: AuthRepository
    init(repository: AuthRepository) { self.repository = repository }
    @MainActor func execute(name: String?, profileImageURL: String?, bio: String?, location: String?, birthday: Date?, hasCompletedSetup: Bool?) async throws {
        try await repository.updateUser(withName: name, profileImageURL: profileImageURL, bio: bio, location: location, birthday: birthday, hasCompletedSetup: hasCompletedSetup)
    }
}

