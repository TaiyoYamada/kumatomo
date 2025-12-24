import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - CreateUserUseCaseTests

/// ユーザー作成UseCaseのテスト
@Suite("CreateUserUseCase Tests")
struct CreateUserUseCaseTests {
    let mockRepository = MockAuthRepository()

    @Test("有効なデータでユーザーを作成できる")
    @MainActor
    func executeShouldCallRepository() async throws {
        // Given
        given(mockRepository)
            .createUser(withEmail: .any, password: .any)
            .willReturn(())

        // When
        let sut = CreateUserUseCaseImpl(repository: mockRepository)
        try await sut.execute(email: "new@example.com", password: "securePass123")

        // Then
        verify(mockRepository)
            .createUser(withEmail: .any, password: .any)
            .called(1)
    }

    @Test("メールが既に存在する場合、エラーをスローする")
    @MainActor
    func executeShouldThrowWhenEmailExists() async {
        // Given
        given(mockRepository)
            .createUser(withEmail: .any, password: .any)
            .willThrow(NSError(domain: "Auth", code: 409))

        // When/Then
        let sut = CreateUserUseCaseImpl(repository: mockRepository)
        await #expect(throws: NSError.self) {
            try await sut.execute(email: "existing@example.com", password: "password")
        }
    }
}
