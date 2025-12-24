import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - SignInUseCaseTests

/// サインインUseCaseのテスト
@Suite("SignInUseCase Tests")
struct SignInUseCaseTests {
    let mockRepository = MockAuthRepository()

    @Test("有効な認証情報でリポジトリが呼ばれる")
    @MainActor
    func executeShouldCallRepository() async throws {
        // Given
        given(mockRepository)
            .signIn(withEmail: .any, password: .any)
            .willReturn(())

        // When
        let sut = SignInUseCaseImpl(repository: mockRepository)
        try await sut.execute(email: "test@example.com", password: "password123")

        // Then
        verify(mockRepository)
            .signIn(withEmail: .any, password: .any)
            .called(1)
    }

    @Test("リポジトリがエラーをスローした場合、エラーが伝播する")
    @MainActor
    func executeShouldPropagateError() async {
        // Given
        given(mockRepository)
            .signIn(withEmail: .any, password: .any)
            .willThrow(NSError(domain: "Auth", code: 401))

        // When/Then
        let sut = SignInUseCaseImpl(repository: mockRepository)
        await #expect(throws: NSError.self) {
            try await sut.execute(email: "test@example.com", password: "wrong")
        }
    }
}
