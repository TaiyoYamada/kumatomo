import Foundation
import Combine
import Factory

final class UserRepositoryImpl: UserRepository {
    private let service: UserAPIService

    init(service: UserAPIService = Container.shared.userAPIService()) {
        self.service = service
    }

    func fetchProfile(userID: String) -> AnyPublisher<User, Error> {
        service.fetchProfile(userID: userID)
    }

    func createProfile(_ user: User) -> AnyPublisher<User, Error> {
        service.createProfile(user)
    }

    func updateProfile(_ user: User) -> AnyPublisher<User, Error> {
        service.updateProfile(user)
    }

    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, Error> {
        service.checkUsernameAvailability(username)
    }
}
