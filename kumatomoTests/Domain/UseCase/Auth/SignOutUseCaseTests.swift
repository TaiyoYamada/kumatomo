import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - SignOutUseCaseTests

/// サインアウトUseCaseのテスト
@Suite("SignOutUseCase Tests")
struct SignOutUseCaseTests {
    let mockRepository = MockAuthRepository()

    @Test("サインアウトでリポジトリが呼ばれる")
    @MainActor
    func executeShouldCallRepository() async throws {
        // Given
        given(mockRepository)
            .signOut()
            .willReturn(())

        // When
        let sut = SignOutUseCaseImpl(repository: mockRepository)
        try await sut.execute()

        // Then
        verify(mockRepository)
            .signOut()
            .called(1)
    }

    @Test("リポジトリがエラーをスローした場合、エラーが伝播する")
    @MainActor
    func executeShouldPropagateError() async {
        // Given
        given(mockRepository)
            .signOut()
            .willThrow(NSError(domain: "Auth", code: 500))

        // When/Then
        let sut = SignOutUseCaseImpl(repository: mockRepository)
        await #expect(throws: NSError.self) {
            try await sut.execute()
        }
    }
}
