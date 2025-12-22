import Combine
@testable import kumatomo
import XCTest

// MARK: - SignInUseCaseTests

final class SignInUseCaseTests: XCTestCase {
    var mockRepository: AuthRepositoryMock!
    var sut: SignInUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = AuthRepositoryMock()
        sut = SignInUseCaseImpl(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    @MainActor
    func test_execute_withValidCredentials_callsRepository() async throws {
        try await sut.execute(email: "test@example.com", password: "password123")
        XCTAssertEqual(mockRepository.signInCallCount, 1)
    }

    @MainActor
    func test_execute_whenRepositoryThrows_propagatesError() async {
        mockRepository.signInHandler = { _, _ in
            throw NSError(domain: "Auth", code: 401)
        }

        do {
            try await sut.execute(email: "test@example.com", password: "wrong")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 401)
        }
    }
}

// MARK: - SignOutUseCaseTests

final class SignOutUseCaseTests: XCTestCase {
    var mockRepository: AuthRepositoryMock!
    var sut: SignOutUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = AuthRepositoryMock()
        sut = SignOutUseCaseImpl(repository: mockRepository)
    }

    @MainActor
    func test_execute_callsRepositorySignOut() async throws {
        try await sut.execute()
        XCTAssertEqual(mockRepository.signOutCallCount, 1)
    }

    @MainActor
    func test_execute_whenRepositoryThrows_propagatesError() async {
        mockRepository.signOutHandler = {
            throw NSError(domain: "Auth", code: 500)
        }

        do {
            try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
        }
    }
}

// MARK: - CreateUserUseCaseTests

final class CreateUserUseCaseTests: XCTestCase {
    var mockRepository: AuthRepositoryMock!
    var sut: CreateUserUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = AuthRepositoryMock()
        sut = CreateUserUseCaseImpl(repository: mockRepository)
    }

    @MainActor
    func test_execute_withValidData_callsRepositoryCreateUser() async throws {
        try await sut.execute(email: "new@example.com", password: "securePass123")
        XCTAssertEqual(mockRepository.createUserCallCount, 1)
    }

    @MainActor
    func test_execute_whenEmailAlreadyExists_throwsError() async {
        mockRepository.createUserHandler = { _, _ in
            throw NSError(domain: "Auth", code: 409)
        }

        do {
            try await sut.execute(email: "existing@example.com", password: "password")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 409)
        }
    }
}

// MARK: - UpdateUserUseCaseTests

final class UpdateUserUseCaseTests: XCTestCase {
    var mockRepository: AuthRepositoryMock!
    var sut: UpdateUserUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = AuthRepositoryMock()
        sut = UpdateUserUseCaseImpl(repository: mockRepository)
    }

    @MainActor
    func test_execute_withAllParameters_callsRepository() async throws {
        try await sut.execute(
            name: "新しい名前",
            profileImageURL: "https://example.com/image.jpg",
            bio: "新しいプロフィール",
            location: "熊本県",
            birthday: Date(),
            hasCompletedSetup: true
        )
        XCTAssertEqual(mockRepository.updateUserCallCount, 1)
    }

    @MainActor
    func test_execute_withOnlyNameUpdate_callsRepository() async throws {
        try await sut.execute(
            name: "名前のみ更新",
            profileImageURL: nil,
            bio: nil,
            location: nil,
            birthday: nil,
            hasCompletedSetup: nil
        )
        XCTAssertEqual(mockRepository.updateUserCallCount, 1)
    }
}
