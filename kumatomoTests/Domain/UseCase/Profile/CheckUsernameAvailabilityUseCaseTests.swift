@testable import kumatomo
import Mockable
import Testing

// MARK: - CheckUsernameAvailabilityUseCaseTests

/// ユーザーネーム重複チェックUseCaseのテスト
@Suite("CheckUsernameAvailabilityUseCase Tests")
struct CheckUsernameAvailabilityUseCaseTests {
    let mockRepository = MockUserRepositoryProtocol()

    @Test("利用可能なユーザーネームの場合、trueを返す")
    func executeShouldReturnTrueForAvailableUsername() async throws {
        // Given
        let username = "newuser"
        given(mockRepository)
            .checkUsernameAvailability(.value(username))
            .willReturn(true)

        // When
        let sut = CheckUsernameAvailabilityUseCase(userRepository: mockRepository)
        let result = try await sut.execute(username: username)

        // Then
        #expect(result == true)
        verify(mockRepository)
            .checkUsernameAvailability(.any)
            .called(1)
    }

    @Test("既に使用されているユーザーネームの場合、falseを返す")
    func executeShouldReturnFalseForTakenUsername() async throws {
        // Given
        let username = "existinguser"
        given(mockRepository)
            .checkUsernameAvailability(.any)
            .willReturn(false)

        // When
        let sut = CheckUsernameAvailabilityUseCase(userRepository: mockRepository)
        let result = try await sut.execute(username: username)

        // Then
        #expect(result == false)
    }

    @Test("空のユーザーネームの場合、リポジトリを呼ばずにfalseを返す")
    func executeShouldReturnFalseForEmptyUsername() async throws {
        // When
        let sut = CheckUsernameAvailabilityUseCase(userRepository: mockRepository)
        let result = try await sut.execute(username: "")

        // Then
        #expect(result == false)
        verify(mockRepository)
            .checkUsernameAvailability(.any)
            .called(0)
    }

    @Test("空白のみのユーザーネームの場合、falseを返す")
    func executeShouldReturnFalseForWhitespaceUsername() async throws {
        // When
        let sut = CheckUsernameAvailabilityUseCase(userRepository: mockRepository)
        let result = try await sut.execute(username: "   ")

        // Then
        #expect(result == false)
    }
}
