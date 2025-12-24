import SwiftUI
import PhotosUI

typealias ModernProfileEditView = ProfileEditView

// MARK: - ProfileEditView

struct ProfileEditView: View {
    @State var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProfileItem: PhotosPickerItem?
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var showSuccessAlert = false
    @State private var showCancelAlert = false
    @State private var showErrorAlert = false
    @State private var showValidationErrors = false
    @State private var showNetworkError = false

    @Environment(ProfileErrorHandler.self) private var errorHandler
    @Environment(NetworkMonitor.self) private var networkMonitor

    @State private var sheetDestination: SheetDestination?

    var onProfileUpdated: (() -> Void)?

    init(user: User, onProfileUpdated: (() -> Void)? = nil) {
        _viewModel = State(wrappedValue: ProfileViewModel(profile: user))
        self.onProfileUpdated = onProfileUpdated
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProfileImageEditRow(
                        selectedProfileItem: $selectedProfileItem,
                        selectedCoverItem: $selectedCoverItem,
                        viewModel: viewModel,
                        sheetDestination: $sheetDestination
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section("基本情報") {
                    ProfileFormRow(
                        title: "名前",
                        text: $viewModel.name,
                        placeholder: "名前を入力してください",
                        validation: viewModel.nameValidation
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        ProfileFormRow(
                            title: "ユーザーネーム",
                            text: $viewModel.username,
                            placeholder: "ユーザーネームを入力してください",
                            validation: viewModel.usernameValidation,
                            prefix: "@"
                        )

                        if viewModel.isValidatingUsername {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("確認中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if let message = viewModel.usernameCheckMessage {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel
                                    .isUsernameAvailable == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(viewModel.isUsernameAvailable == true ? .green : .red)
                                    .font(.caption)

                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(viewModel.isUsernameAvailable == true ? .green : .red)
                            }
                        }
                    }
                }

                Section("追加情報") {
                    ProfileBioRow(
                        text: $viewModel.bio,
                        validation: viewModel.bioValidation
                    )

                    ProfileCityPickerRow(
                        selectedCity: $viewModel.selectedCity
                    )

                    ProfileDatePickerRow(
                        title: "生年月日",
                        date: $viewModel.birthday
                    )
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                            .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        handleCancelTapped()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await handleSaveProfile()
                        }
                    }
                    .disabled(!viewModel.canSaveProfile)
                    .foregroundColor(viewModel.canSaveProfile ? .accentColor : .secondary)
                    .fontWeight(.semibold)
                    .overlay(
                        Group {
                            if viewModel.isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.secondary)
                            }
                        }
                    )
                }
            }
            .alert("変更を破棄しますか？", isPresented: $showCancelAlert) {
                Button("破棄", role: .destructive) {
                    viewModel.resetFormFields()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("保存されていない変更があります。本当に破棄しますか？")
            }
            .alert("エラー", isPresented: errorAlertBinding) {
                if errorHandler.currentError?.isRecoverable == true {
                    Button("再試行") {
                        Task {
                            await errorHandler.retryLastAction()
                        }
                    }
                    Button("キャンセル", role: .cancel) {
                        errorHandler.clearError()
                    }
                } else {
                    Button("OK") {
                        errorHandler.clearError()
                    }
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(errorHandler.getDisplayMessage(for: error))
                }
            }
            .onChange(of: viewModel.showValidationErrors) { show in
                showValidationErrors = show
            }
            .onChange(of: viewModel.showSuccessAlert) { show in
                showSuccessAlert = show
            }
            .onChange(of: viewModel.showError) { show in
                if show {
                    errorHandler.handleError(
                        ProfileError.profileUpdateFailed(
                            NSError(domain: "ProfileEdit", code: 0, userInfo: [
                                NSLocalizedDescriptionKey: viewModel.errorMessage ?? "不明なエラー"
                            ])
                        )
                    )
                }
            }
            .overlay {
                if viewModel.isProcessing {
                    ProfileLoadingOverlay(
                        isLoading: viewModel.isProcessing,
                        message: getLoadingMessage()
                    )
                }
            }
            .overlay(alignment: .top) {
                if !networkMonitor.isConnected {
                    NetworkStatusBanner()
                }
            }
            .overlay {
                if showValidationErrors, !viewModel.validationErrorMessages.isEmpty {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay(
                            ValidationErrorView(
                                errors: viewModel.validationErrorMessages,
                                onDismiss: {
                                    showValidationErrors = false
                                    viewModel.clearValidationErrors()
                                }
                            )
                            .padding(.horizontal, 20)
                        )
                }
            }
            .overlay {
                if showSuccessAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay(
                            ProfileSuccessIndicator(
                                message: viewModel.successMessage,
                                onDismiss: {
                                    showSuccessAlert = false
                                    viewModel.clearSuccessMessage()
                                    onProfileUpdated?()
                                    dismiss()
                                }
                            )
                            .padding(.horizontal, 20)
                        )
                }
            }
            .overlay {
                VStack {
                    if viewModel.isProfileImageUploading {
                        ProfileProgressIndicator(
                            progress: viewModel.profileImageUploadProgress,
                            isUploading: true,
                            uploadType: "プロフィール画像",
                            onCancel: {
                                viewModel.cancelProfileImageUpload()
                            }
                        )
                        .padding(.horizontal, 20)
                    }

                    if viewModel.isCoverImageUploading {
                        ProfileProgressIndicator(
                            progress: viewModel.coverImageUploadProgress,
                            isUploading: true,
                            uploadType: "カバー画像",
                            onCancel: {
                                viewModel.cancelCoverImageUpload()
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .withSheetRouter(sheet: $sheetDestination)
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding<Bool>(
            get: { errorHandler.showErrorAlert },
            set: { newValue in
                if !newValue {
                    errorHandler.dismissError()
                } else {
                    errorHandler.showErrorAlert = newValue
                }
            }
        )
    }

    private var isFormValid: Bool {
        return viewModel.isFormValid && networkMonitor.isConnected
    }

    private func handleCancelTapped() {
        if viewModel.hasUnsavedChanges {
            showCancelAlert = true
        } else {
            dismiss()
        }
    }

    private func handleSaveProfile() async {
        guard networkMonitor.isConnected else {
            errorHandler.handleError(ProfileError.offlineError)
            return
        }

        guard viewModel.hasUnsavedChanges else {
            viewModel.showSuccessMessage("変更がありません")
            return
        }

        let success = await viewModel.updateProfile()

        if success {
            print("✅ Profile save completed successfully - images and data updated")
        } else {
            print("❌ Profile save failed - check ViewModel error state")
        }
    }

    private func getLoadingMessage() -> String {
        if viewModel.isProfileImageUploading, viewModel.isCoverImageUploading {
            return "画像をアップロード中..."
        } else if viewModel.isProfileImageUploading {
            return "プロフィール画像をアップロード中..."
        } else if viewModel.isCoverImageUploading {
            return "カバー画像をアップロード中..."
        } else if viewModel.isProcessing {
            return "プロフィールを保存中..."
        } else {
            return "処理中..."
        }
    }
}
