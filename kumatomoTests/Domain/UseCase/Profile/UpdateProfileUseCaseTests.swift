@testable import kumatomo
import Mockable
import Testing

// MARK: - UpdateProfileUseCaseTests

/// プロフィール更新UseCaseのテスト
@Suite("UpdateProfileUseCase Tests")
struct UpdateProfileUseCaseTests {
    let mockRepository = MockUserRepositoryProtocol()

    @Test("有効なプロフィールで更新できる")
    func executeShouldUpdateProfile() async throws {
        // Given
        let user = UserFixtures.testUser
        given(mockRepository)
            .updateProfile(.any)
            .willReturn(user)

        // When
        let sut = UpdateProfileUseCase(userRepository: mockRepository)
        let result = try await sut.execute(user: user)

        // Then
        #expect(result.id == user.id)
        verify(mockRepository)
            .updateProfile(.any)
            .called(1)
    }

    @Test("リポジトリがエラーをスローした場合、エラーが伝播する")
    func executeShouldPropagateError() async {
        // Given
        let user = UserFixtures.testUser
        given(mockRepository)
            .updateProfile(.any)
            .willThrow(TestError.network)

        // When/Then
        let sut = UpdateProfileUseCase(userRepository: mockRepository)
        await #expect(throws: Error.self) {
            _ = try await sut.execute(user: user)
        }
    }
}
