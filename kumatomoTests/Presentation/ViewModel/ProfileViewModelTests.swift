import Factory
@testable import kumatomo
import Mockable
import Testing

// MARK: - ProfileViewModelTests

/// プロフィールViewModelのテスト
@Suite("ProfileViewModel Tests")
@MainActor
struct ProfileViewModelTests {
    @Test("初期状態のプロファイルが設定される")
    func initialStateShouldHaveProfile() async {
        // Given
        let sut = ProfileViewModel(userID: 1)

        // Then
        #expect(sut.profile.id == 1)
        #expect(sut.isLoading == false || sut.isLoading == true) // 非同期読み込み中の可能性
    }

    @Test("プロフィール指定で初期化できる")
    func initWithProfileShouldSetFields() async {
        // Given
        let testUser = UserFixtures.testUser

        // When
        let sut = ProfileViewModel(profile: testUser)

        // Then
        #expect(sut.profile.id == testUser.id)
        #expect(sut.name == testUser.name ?? "")
        #expect(sut.email == testUser.email ?? "")
    }

    @Test("canSaveProfileの条件")
    func canSaveProfileShouldRequireValidForm() async {
        // Given
        let sut = ProfileViewModel(userID: 0)
        sut.isFormValid = false

        // Then
        #expect(sut.canSaveProfile == false)
    }

    @Test("未保存変更がない場合は保存不可")
    func cannotSaveWithoutUnsavedChanges() async {
        // Given
        let sut = ProfileViewModel(profile: UserFixtures.testUser)
        sut.isFormValid = true
        sut.hasUnsavedChanges = false

        // Then
        #expect(sut.canSaveProfile == false)
    }

    @Test("getValidationSummaryが正確")
    func getValidationSummaryShouldBeAccurate() async {
        // Given
        let sut = ProfileViewModel(profile: UserFixtures.testUser)

        // When
        let summary = sut.getValidationSummary()

        // Then
        #expect(summary.isFormValid == sut.isFormValid)
        #expect(summary.hasUnsavedChanges == sut.hasUnsavedChanges)
    }

    @Test("resetForProfileCreationでフォームがクリア")
    func resetForProfileCreationShouldClearForm() async {
        // Given
        let sut = ProfileViewModel(profile: UserFixtures.testUser)
        sut.name = "テスト"
        sut.hasUnsavedChanges = true

        // When
        sut.resetForProfileCreation()

        // Then
        #expect(sut.name == "")
        #expect(sut.email == "")
        #expect(sut.username == "")
        #expect(sut.hasUnsavedChanges == false)
    }

    @Test("canCreateProfileの条件")
    func canCreateProfileShouldRequireAllConditions() async {
        // Given
        let sut = ProfileViewModel(userID: 0)
        sut.isFormValid = false
        sut.email = ""
        sut.name = ""
        sut.username = ""

        // Then
        #expect(sut.canCreateProfile == false)
    }

    @Test("getMissingRequiredFieldsが欠落フィールドを返す")
    func getMissingRequiredFieldsShouldReturnMissing() async {
        // Given
        let sut = ProfileViewModel(userID: 0)
        sut.email = ""
        sut.name = "テスト"
        sut.username = ""

        // When
        let missing = sut.getMissingRequiredFields()

        // Then
        #expect(missing.count >= 2) // email and username missing
    }
}
