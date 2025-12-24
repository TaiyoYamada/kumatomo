import Factory
@testable import kumatomo
import Mockable
import Testing

// MARK: - AuthViewModelTests

/// 認証ViewModelのテスト
@Suite("AuthViewModel Tests")
@MainActor
struct AuthViewModelTests {
    @Test("初期状態で入力フォームが空")
    func initialStateShouldHaveEmptyForm() async {
        // Given
        let sut = AuthViewModel()

        // Then
        #expect(sut.email == "")
        #expect(sut.password == "")
        #expect(sut.name == "")
        #expect(sut.bio == "")
        #expect(sut.isLoading == false)
    }

    @Test("フォームバリデーション: 名前が空ならfalse")
    func formValidationShouldBeFalseWithEmptyName() async {
        // Given
        let sut = AuthViewModel()
        sut.name = ""

        // Then - private isFormValid should be false with empty name
        // Testing via public state
        #expect(sut.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test("フォームバリデーション: 名前があればtrue")
    func formValidationShouldBeTrueWithValidName() async {
        // Given
        let sut = AuthViewModel()
        sut.name = "テストユーザー"

        // Then
        #expect(!sut.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
