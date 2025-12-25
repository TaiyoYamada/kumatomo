import Foundation
import Combine

final class AuthRepositoryImpl: AuthRepository {
    private let service: AuthService

    init(service: AuthService = .shared) {
        self.service = service
    }

    var isAuthenticated: Bool { service.isAuthenticated }
    var currentUser: User? { service.currentUser }

    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        service.$isAuthenticated.eraseToAnyPublisher()
    }

    var currentUserPublisher: AnyPublisher<User?, Never> {
        service.$currentUser.eraseToAnyPublisher()
    }

    @MainActor
    func signIn(withEmail email: String, password: String) async throws {
        try await service.signIn(withEmail: email, password: password)
    }

    @MainActor
    func signOut() async throws {
        try await service.signOut()
    }

    @MainActor
    func createUser(withEmail email: String, password: String, passwordConfirmation: String) async throws {
        try await service.createUser(withEmail: email, password: password, passwordConfirmation: passwordConfirmation)
    }

    @MainActor
    func updateUser(
        withName name: String?,
        profileImageURL: String?,
        bio: String?,
        location: String?,
        birthday: Date?,
        hasCompletedSetup: Bool?
    ) async throws {
        try await service.updateUser(
            withName: name,
            profileImageURL: profileImageURL,
            bio: bio,
            location: location,
            birthday: birthday,
            hasCompletedSetup: hasCompletedSetup
        )
    }

    @MainActor
    func refreshToken() async throws {
        try await service.refreshToken()
    }

    @MainActor
    func fetchCurrentUser() async throws {
        try await service.fetchCurrentUser()
    }
}
