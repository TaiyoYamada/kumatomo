import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - UpdateUserUseCaseTests

/// ユーザー更新UseCaseのテスト
@Suite("UpdateUserUseCase Tests")
struct UpdateUserUseCaseTests {
    let mockRepository = MockAuthRepository()

    @Test("全パラメータでリポジトリを呼び出せる")
    @MainActor
    func executeShouldCallRepositoryWithAllParams() async throws {
        // Given
        given(mockRepository)
            .updateUser(
                withName: .any,
                profileImageURL: .any,
                bio: .any,
                location: .any,
                birthday: .any,
                hasCompletedSetup: .any
            )
            .willReturn(())

        // When
        let sut = UpdateUserUseCaseImpl(repository: mockRepository)
        try await sut.execute(
            name: "新しい名前",
            profileImageURL: "https://example.com/image.jpg",
            bio: "新しいプロフィール",
            location: "熊本県",
            birthday: Date(),
            hasCompletedSetup: true
        )

        // Then
        verify(mockRepository)
            .updateUser(
                withName: .any,
                profileImageURL: .any,
                bio: .any,
                location: .any,
                birthday: .any,
                hasCompletedSetup: .any
            )
            .called(1)
    }

    @Test("名前のみの更新でリポジトリを呼び出せる")
    @MainActor
    func executeShouldCallRepositoryWithNameOnly() async throws {
        // Given
        given(mockRepository)
            .updateUser(
                withName: .any,
                profileImageURL: .any,
                bio: .any,
                location: .any,
                birthday: .any,
                hasCompletedSetup: .any
            )
            .willReturn(())

        // When
        let sut = UpdateUserUseCaseImpl(repository: mockRepository)
        try await sut.execute(
            name: "名前のみ更新",
            profileImageURL: nil,
            bio: nil,
            location: nil,
            birthday: nil,
            hasCompletedSetup: nil
        )

        // Then
        verify(mockRepository)
            .updateUser(
                withName: .any,
                profileImageURL: .any,
                bio: .any,
                location: .any,
                birthday: .any,
                hasCompletedSetup: .any
            )
            .called(1)
    }
}
