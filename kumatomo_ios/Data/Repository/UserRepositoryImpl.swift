import Combine
import Factory
import Foundation

final class UserRepositoryImpl: UserRepositoryProtocol {
    private let service: UserAPIService

    init(service: UserAPIService = Container.shared.userAPIService()) {
        self.service = service
    }

    func fetchProfile(userID: String) async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = service.fetchProfile(userID: userID)
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

    func createProfile(_ user: User) async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = service.createProfile(user)
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
