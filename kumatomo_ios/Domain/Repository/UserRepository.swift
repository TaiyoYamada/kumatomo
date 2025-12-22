import Foundation
import Combine

protocol UserRepositoryProtocol {
    func fetchProfile(userID: String) -> AnyPublisher<User, Error>
    func createProfile(_ user: User) -> AnyPublisher<User, Error>
    func updateProfile(_ user: User) -> AnyPublisher<User, Error>
    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, Error>

    // Async versions for UseCase
    func updateProfile(_ user: User) async throws -> User
    func checkUsernameAvailability(_ username: String) async throws -> Bool
}
