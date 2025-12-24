import Combine
import Foundation
import Mockable

@Mockable
protocol UserRepositoryProtocol {
    func fetchProfile(userID: String) async throws -> User
    func createProfile(_ user: User) async throws -> User
    func updateProfile(_ user: User) async throws -> User
    func checkUsernameAvailability(_ username: String) async throws -> Bool
}
