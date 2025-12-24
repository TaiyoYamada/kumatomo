import Factory
@testable import kumatomo
import Mockable
import Testing

// MARK: - CommentViewModelTests

/// コメントViewModelのテスト
@Suite("CommentViewModel Tests")
@MainActor
struct CommentViewModelTests {
    @Test("初期状態では空のコメント")
    func initialStateShouldBeEmpty() async {
        // Given
        let sut = CommentViewModel()

        // Then
        #expect(sut.commentText == "")
        #expect(sut.selectedImage == nil)
        #expect(sut.isSubmitting == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("新しいコメントテキストの更新")
    func commentTextShouldBeUpdated() async {
        // Given
        let sut = CommentViewModel()

        // When
        sut.commentText = "テストコメント"

        // Then
        #expect(sut.commentText == "テストコメント")
    }

    @Test("空のコメントは送信不可")
    func cannotSubmitEmptyComment() async {
        // Given
        let sut = CommentViewModel()
        sut.commentText = ""
        sut.selectedImage = nil

        // Then - canSubmit should be false for empty text and no image
        #expect(sut.canSubmit == false)
    }

    @Test("テキストがあれば送信可能")
    func canSubmitWithText() async {
        // Given
        let sut = CommentViewModel()
        sut.commentText = "テストコメント"

        // Then
        #expect(sut.canSubmit == true)
    }

    @Test("文字数カウントが正確")
    func characterCountShouldBeAccurate() async {
        // Given
        let sut = CommentViewModel()
        sut.commentText = "テスト" // 3文字

        // Then
        #expect(sut.characterCount == 3)
    }

    @Test("clearFormでリセットされる")
    func clearFormShouldReset() async {
        // Given
        let sut = CommentViewModel()
        sut.commentText = "テスト"
        sut.errorMessage = "エラー"

        // When
        sut.clearForm()

        // Then
        #expect(sut.commentText == "")
        #expect(sut.errorMessage == nil)
        #expect(sut.selectedImage == nil)
    }

    @Test("hasContentはテキストがあればtrue")
    func hasContentShouldBeTrueWithText() async {
        // Given
        let sut = CommentViewModel()
        sut.commentText = "コメント"

        // Then
        #expect(sut.hasContent == true)
    }
}
