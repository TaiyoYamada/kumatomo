import Factory
@testable import kumatomo
import Mockable
import Testing

// MARK: - PostViewModelTests

/// 投稿作成ViewModelのテスト
@Suite("PostViewModel Tests")
@MainActor
struct PostViewModelTests {
    @Test("初期状態でフォームが空")
    func initialStateShouldBeEmpty() async {
        // Given
        let sut = PostViewModel()

        // Then
        #expect(sut.postContent == "")
        #expect(sut.selectedImages.isEmpty)
        #expect(sut.tags.isEmpty)
        #expect(sut.selectedTags.contains("熊本県全体"))
        #expect(sut.isSubmitting == false)
    }

    @Test("コンテンツなしでは投稿不可")
    func cannotPostWithoutContent() async {
        // Given
        let sut = PostViewModel()
        sut.postContent = ""
        sut.selectedImages = []

        // Then
        #expect(sut.canPost == false)
    }

    @Test("テキストがあれば投稿可能")
    func canPostWithText() async {
        // Given
        let sut = PostViewModel()
        sut.postContent = "テスト投稿"

        // Then
        #expect(sut.canPost == true)
    }

    @Test("300文字超過は投稿不可")
    func cannotPostWithOverLimitContent() async {
        // Given
        let sut = PostViewModel()
        sut.postContent = String(repeating: "あ", count: 301)

        // Then
        #expect(sut.canPost == false)
    }

    @Test("タグなしでは投稿不可")
    func cannotPostWithoutTags() async {
        // Given
        let sut = PostViewModel()
        sut.postContent = "テスト"
        sut.selectedTags = []

        // Then
        #expect(sut.canPost == false)
    }

    @Test("タグ切り替えが正常動作")
    func toggleTagShouldWork() async {
        // Given
        let sut = PostViewModel()
        let tagToAdd = "熊本市"

        // When - add tag
        sut.toggleTag(tagToAdd)

        // Then
        #expect(sut.selectedTags.contains(tagToAdd))

        // When - remove tag
        sut.toggleTag(tagToAdd)

        // Then
        #expect(!sut.selectedTags.contains(tagToAdd))
    }

    @Test("最低1つのタグは残る")
    func atLeastOneTagRemains() async {
        // Given
        let sut = PostViewModel()
        sut.selectedTags = ["熊本県全体"]

        // When - try to remove last tag
        sut.toggleTag("熊本県全体")

        // Then - tag should remain
        #expect(!sut.selectedTags.isEmpty)
    }

    @Test("resetFormで全てクリアされる")
    func resetFormShouldClearAll() async {
        // Given
        let sut = PostViewModel()
        sut.postContent = "テスト"
        sut.tags = ["タグ1"]
        sut.errorMessage = "エラー"

        // When
        sut.resetForm()

        // Then
        #expect(sut.postContent == "")
        #expect(sut.tags.isEmpty)
        #expect(sut.selectedTags.contains("熊本県全体"))
        #expect(sut.errorMessage == nil)
    }

    @Test("コンテンツバリデーション: 空")
    func contentValidationEmpty() async {
        // Given
        let sut = PostViewModel()
        sut.postContent = ""
        sut.selectedImages = []

        // When
        let state = sut.getContentValidationState()

        // Then
        #expect(state == .empty)
    }

    @Test("コンテンツバリデーション: 有効")
    func contentValidationValid() async {
        // Given
        let sut = PostViewModel()
        sut.postContent = "テスト投稿内容"

        // When
        let state = sut.getContentValidationState()

        // Then
        #expect(state == .valid)
    }

    @Test("タグバリデーション: タグなし")
    func tagValidationNoTags() async {
        // Given
        let sut = PostViewModel()
        sut.selectedTags = []

        // When
        let state = sut.getTagValidationState()

        // Then
        #expect(state == .noTagsSelected)
    }

    @Test("編集開始で状態が設定される")
    func startEditingShouldSetState() async {
        // Given
        let sut = PostViewModel()
        let post = PostFixtures.createPost(content: "編集する投稿")

        // When
        sut.startEditing(post)

        // Then
        #expect(sut.isEditing == true)
        #expect(sut.editingPost?.id == post.id)
        #expect(sut.postContent == "編集する投稿")
    }

    @Test("編集キャンセルでリセット")
    func cancelEditingShouldReset() async {
        // Given
        let sut = PostViewModel()
        sut.startEditing(PostFixtures.createPost())

        // When
        sut.cancelEditing()

        // Then
        #expect(sut.isEditing == false)
        #expect(sut.editingPost == nil)
    }
}
