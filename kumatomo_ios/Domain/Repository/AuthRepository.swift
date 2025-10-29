import Foundation
import Combine

// Domain layer protocol for authentication concerns
protocol AuthRepository {
    // Current values
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }

    // Streams for state changes
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    var currentUserPublisher: AnyPublisher<User?, Never> { get }

    // Actions
    @MainActor func signIn(withEmail email: String, password: String) async throws
    @MainActor func signOut() async throws
    @MainActor func createUser(withEmail email: String, password: String) async throws
    @MainActor func updateUser(withName name: String?, profileImageURL: String?, bio: String?, location: String?, birthday: Date?, hasCompletedSetup: Bool?) async throws
    @MainActor func refreshToken() async throws
    @MainActor func fetchCurrentUser() async throws
}
