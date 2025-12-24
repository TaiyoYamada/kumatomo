import Factory
@testable import kumatomo
import Mockable
import Testing

// MARK: - PostDetailViewModelTests

/// 投稿詳細ViewModelのテスト
@Suite("PostDetailViewModel Tests")
@MainActor
struct PostDetailViewModelTests {
    @Test("初期状態ではnilのpost")
    func initialStateShouldHaveNilPost() async {
        // Given
        let sut = PostDetailViewModel()

        // Then
        #expect(sut.post == nil)
        #expect(sut.comments.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("コメント文字数カウントが正確")
    func commentCharacterCountShouldBeAccurate() async {
        // Given
        let sut = PostDetailViewModel()
        sut.commentText = "テスト"

        // Then
        #expect(sut.commentCharacterCount == 3)
    }

    @Test("コメント文字数制限超過を検出できる")
    func shouldDetectCommentOverLimit() async {
        // Given
        let sut = PostDetailViewModel()
        sut.commentText = String(repeating: "あ", count: 501)

        // Then
        #expect(sut.isCommentOverLimit == true)
    }

    @Test("空コメントは送信不可")
    func cannotAddEmptyComment() async {
        // Given
        let sut = PostDetailViewModel()
        sut.commentText = ""
        sut.selectedCommentImage = nil

        // Then
        #expect(sut.canAddComment == false)
    }

    @Test("テキストがあればコメント送信可能")
    func canAddCommentWithText() async {
        // Given
        let sut = PostDetailViewModel()
        sut.commentText = "コメント内容"

        // Then
        #expect(sut.canAddComment == true)
    }

    @Test("clearCommentFormでリセットされる")
    func clearCommentFormShouldReset() async {
        // Given
        let sut = PostDetailViewModel()
        sut.commentText = "テスト"

        // When
        sut.clearCommentForm()

        // Then
        #expect(sut.commentText == "")
        #expect(sut.selectedCommentImage == nil)
    }

    @Test("バリデーションで空コメントは失敗")
    func validateEmptyCommentShouldFail() async {
        // Given
        let sut = PostDetailViewModel()
        sut.commentText = ""
        sut.selectedCommentImage = nil

        // When
        let result = sut.validateCommentContent("")

        // Then
        #expect(result.isValid == false)
        #expect(result.errorMessage != nil)
    }

    @Test("バリデーションで長すぎるコメントは失敗")
    func validateTooLongCommentShouldFail() async {
        // Given
        let sut = PostDetailViewModel()
        let longText = String(repeating: "あ", count: 501)

        // When
        let result = sut.validateCommentContent(longText)

        // Then
        #expect(result.isValid == false)
    }

    @Test("resetで全てクリアされる")
    func resetShouldClearEverything() async {
        // Given
        let sut = PostDetailViewModel()
        sut.commentText = "テスト"
        sut.isLoading = true

        // When
        sut.reset()

        // Then
        #expect(sut.post == nil)
        #expect(sut.comments.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.commentText == "")
    }
}
