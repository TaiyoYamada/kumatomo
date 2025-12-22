import Foundation
import Combine
import Factory

final class UserRepositoryImpl: UserRepositoryProtocol {
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

    // MARK: - Async versions

    func updateProfile(_ user: User) async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = service.updateProfile(user)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { user in
                        continuation.resume(returning: user)
                    }
                )
        }
    }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = service.checkUsernameAvailability(username)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { isAvailable in
                        continuation.resume(returning: isAvailable)
                    }
                )
        }
    }
}
