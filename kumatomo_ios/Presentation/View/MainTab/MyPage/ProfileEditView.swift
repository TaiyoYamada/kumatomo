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
                        title: "メールアドレス",
                        text: $viewModel.email,
                        placeholder: "メールアドレスを入力してください",
                        validation: viewModel.emailValidation,
                        keyboardType: .emailAddress
                    )

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

                    ProfileFormRow(
                        title: "出身地",
                        text: $viewModel.location,
                        placeholder: "出身地を入力してください",
                        validation: viewModel.locationValidation
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

// MARK: - ProfileFormRow

struct ProfileFormRow: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let validation: ValidationResult
    var keyboardType: UIKeyboardType = .default
    var prefix: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            HStack {
                if let prefix {
                    Text(prefix)
                        .foregroundColor(.secondary)
                        .font(.body)
                }

                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            if !validation.isValid, let errorMessage = validation.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ProfileBioRow

struct ProfileBioRow: View {
    @Binding var text: String
    let validation: ValidationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("自己紹介")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(text.count)/500")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if text.isEmpty {
                            HStack {
                                VStack {
                                    Text("自己紹介を入力してください")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 16)
                                        .padding(.leading, 12)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                )

            if !validation.isValid, let errorMessage = validation.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ProfileDatePickerRow

struct ProfileDatePickerRow: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("この情報は公開されません。年齢に基づいてよりよいコンテンツを表示するために使用されます。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ProfileImageEditRow

struct ProfileImageEditRow: View {
    @Binding var selectedProfileItem: PhotosPickerItem?
    @Binding var selectedCoverItem: PhotosPickerItem?
    @Bindable var viewModel: ProfileViewModel
    @Binding var sheetDestination: SheetDestination?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Group {
                    if let coverImage = viewModel.coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: min(120, UIScreen.main.bounds.height * 0.15))
                            .clipped()
                    } else if let coverImageURL = viewModel.profile.coverImageURL, !coverImageURL.isEmpty {
                        AsyncImage(url: URL(string: coverImageURL)) { phase in
                            switch phase {
                            case .empty:
                                defaultCoverImageGradient
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: min(120, UIScreen.main.bounds.height * 0.15))
                                    .clipped()
                            case .failure:
                                defaultCoverImageGradient
                            @unknown default:
                                defaultCoverImageGradient
                            }
                        }
                    } else {
                        defaultCoverImageGradient
                    }
                }
                .allowsHitTesting(false)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        Button(action: {
                            sheetDestination = .coverImageEdit(
                                selectedItem: $selectedCoverItem,
                                onDelete: {
                                    viewModel.deleteCoverImage()
                                }
                            )
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                Text("カバー画像")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(12)
                    }
                }
            }

            HStack {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        if let profileImage = viewModel.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 74, height: 74)
                                .clipShape(Circle())
                        } else if let profileImageURL = viewModel.profile.profileImageURL, !profileImageURL.isEmpty {
                            AsyncImage(url: URL(string: profileImageURL)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .tint(.secondary)
                                case let .success(image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 74, height: 74)
                                        .clipShape(Circle())
                                case .failure:
                                    defaultProfileIcon
                                @unknown default:
                                    defaultProfileIcon
                                }
                            }
                        } else {
                            defaultProfileIcon
                        }
                    }
                    .allowsHitTesting(false)

                    Button(action: {
                        sheetDestination = .profileImageEdit(
                            selectedItem: $selectedProfileItem,
                            onDelete: {
                                viewModel.deleteProfileImage()
                            }
                        )
                    }) {

                        Circle()
                            .fill(Color.orange)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .medium))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .offset(x: 4, y: 4)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, -40)
            .padding(.bottom, 16)
        }
        .onChange(of: selectedProfileItem) { newItem in
            handleProfileImageSelection(newItem)
        }
        .onChange(of: selectedCoverItem) { newItem in
            handleCoverImageSelection(newItem)
        }
    }

    private var defaultCoverImageGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.orange.opacity(0.6),
                Color.purple.opacity(0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: min(120, UIScreen.main.bounds.height * 0.15))
    }

    private var defaultProfileIcon: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 32))
            .foregroundColor(.secondary)
    }

    private func handleProfileImageSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem else {
            return
        }

        Task {
            do {
                if let data = try await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {

                    guard validateImageForProfile(uiImage, type: .profile) else {
                        await MainActor.run {
                            selectedProfileItem = nil
                        }
                        return
                    }

                    await MainActor.run {
                        viewModel.updateProfileImage(uiImage)
                        selectedProfileItem = nil
                    }
                }
            } catch {
                print("❌ Error loading profile image: \(error.localizedDescription)")
                await MainActor.run {
                    selectedProfileItem = nil
                }
            }
        }
    }

    private func handleCoverImageSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem else {
            return
        }

        Task {
            do {
                if let data = try await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {

                    guard validateImageForProfile(uiImage, type: .cover) else {
                        await MainActor.run {
                            selectedCoverItem = nil
                        }
                        return
                    }

                    await MainActor.run {
                        viewModel.updateCoverImage(uiImage)
                        selectedCoverItem = nil
                    }
                }
            } catch {
                print("❌ Error loading cover image: \(error.localizedDescription)")
                await MainActor.run {
                    selectedCoverItem = nil
                }
            }
        }
    }

    private func validateImageForProfile(_ image: UIImage, type: ImageEditSheet.ImageType) -> Bool {
        let maxDimension: CGFloat = type == .profile ? 1_024 : 2_048
        let imageSize = max(image.size.width, image.size.height)

        if imageSize > maxDimension {
            return true
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return false
        }

        let fileSizeMB = Double(imageData.count) / (1_024 * 1_024)
        let maxFileSizeMB = 10.0

        if fileSizeMB > maxFileSizeMB {
            return true
        }

        return true
    }
}
