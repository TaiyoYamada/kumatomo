import Foundation
import Combine

@MainActor
protocol UserRepository {
    func fetchProfile(userID: String) -> AnyPublisher<User, Error>
    func createProfile(_ user: User) -> AnyPublisher<User, Error>
    func updateProfile(_ user: User) -> AnyPublisher<User, Error>
    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, Error>
}
