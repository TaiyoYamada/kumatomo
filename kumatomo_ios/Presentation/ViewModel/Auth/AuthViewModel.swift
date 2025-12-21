import Foundation
import PhotosUI
import SwiftUI
import Factory

@MainActor
@Observable
final class AuthViewModel {
    // MARK: - Properties

    var isAuthenticated = false
    var currentUser: User?
    var accounts: [User] = []
    var selectedAccount: User?

    var hasCompletedSetup: Bool?
    var email = ""
    var password = ""
    var name = ""
    var bio = ""
    var birthDate: Date = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    var location = ""
    var birthday = Date()
    var profileImage: UIImage?
    var selectedImage: PhotosPickerItem?

    var errorMessage: String? = ""
    var isLoading = false

    // MARK: - Dependencies

    @ObservationIgnored @Injected(\.authRepository) var authRepository
    @ObservationIgnored @Injected(\.imageUploadRepository) var imageUploader
    @ObservationIgnored @Injected(\.signInUseCase) var signInUseCase
    @ObservationIgnored @Injected(\.signOutUseCase) var signOutUseCase
    @ObservationIgnored @Injected(\.createUserUseCase) var createUserUseCase
    @ObservationIgnored @Injected(\.updateUserUseCase) var updateUserUseCase

    @ObservationIgnored private var observationTask: Task<Void, Never>?

    // MARK: - Initializer

    init() {
        // 初期状態をサービスから取得
        isAuthenticated = authRepository.isAuthenticated
        currentUser = authRepository.currentUser
        hasCompletedSetup = currentUser?.hasCompletedSetup

        startObserving()
    }

    deinit {
        observationTask?.cancel()
    }

    // MARK: - Private Methods

    private func startObserving() {
        observationTask = Task { [weak self] in
            guard let self else { return }

            // 認証状態とユーザー情報の変化を監視（async stream）
            for await user in authRepository.currentUserPublisher.values {
                guard !Task.isCancelled else { break }

                // 認証状態の更新（重複更新を防止）
                let newAuthState = authRepository.isAuthenticated
                if isAuthenticated != newAuthState {
                    isAuthenticated = newAuthState
                }

                // ユーザー情報の更新（ID が変わった場合のみ）
                if currentUser?.id != user?.id {
                    currentUser = user
                }

                // hasCompletedSetup の更新（値が変わった場合のみ）
                let newSetupState = user?.hasCompletedSetup
                if hasCompletedSetup != newSetupState {
                    hasCompletedSetup = newSetupState
                }
            }
        }
    }

    @MainActor
    func signIn() async {
        isLoading = true
        errorMessage = ""

        do {
            try await signInUseCase.execute(email: email, password: password)
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    //  - サインアップ処理

    /// 新規ユーザーを作成
    @MainActor
    func createUser() async {
        isLoading = true
        errorMessage = ""

        do {
            try await createUserUseCase.execute(email: email, password: password)

            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    //  - サインアウト処理

    /// ログアウト
    @MainActor
    func signOut() async {
        isLoading = true
        errorMessage = ""

        do {
            try await signOutUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // - プロフィール画像アップロード

    private func handleSubmit() {
        guard isFormValid else { return }
        isLoading = true

        Task {
            do {
                // プロフィール画像がある場合はアップロード
                var profileImageURL: String?
                if let image = profileImage {
                    profileImageURL = try await uploadProfileImage(image)
                }

                // 初期設定完了を記録
                self.hasCompletedSetup = true

                // ユーザー情報を更新
                try await updateUserUseCase.execute(
                    name: name,
                    profileImageURL: profileImageURL,
                    bio: bio,
                    location: location,
                    birthday: birthDate,
                    hasCompletedSetup: true
                )

                await MainActor.run {
                    isLoading = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "プロフィール情報の更新に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }

    private var isFormValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadProfileImage() {
        Task {
            guard let item = selectedImage else { return }
            do {
                let data = try await item.loadTransferable(type: Data.self)
                if let data,
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImage = uiImage
                    }
                }
            } catch {
                print("DEBUG: 画像読み込み失敗: \(error)")
            }
        }
    }

    /// すべての入力フォームを初期状態に戻す
    private func resetForm() {
        email = ""
        password = ""
        name = ""
        profileImage = nil
        selectedImage = nil
    }

    // 初期設定を保存
    func saveInitialSetup() async -> Bool {
        isLoading = true
        errorMessage = ""

        // バリデーション
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "名前を入力してください"
            isLoading = false
            return false
        }

        do {
            // 画像がある場合はアップロード
            var profileImageURL: String?
            if let image = profileImage {
                profileImageURL = try await uploadProfileImage(image)
            }

            // プロフィール情報を更新

            try await updateUserUseCase.execute(
                name: name,
                profileImageURL: profileImageURL,
                bio: bio,
                location: location,
                birthday: birthDate,
                hasCompletedSetup: true
            )

            isLoading = false
            return true
        } catch {
            errorMessage = "プロフィールの保存に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // プロフィール画像のアップロード
    private func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw ImageUploadError.imageConversionFailed
        }
        return try await imageUploader.uploadImage(data, endpoint: "/upload-image")
    }
}
