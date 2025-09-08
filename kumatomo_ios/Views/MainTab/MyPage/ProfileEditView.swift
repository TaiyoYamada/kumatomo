import SwiftUI
import PhotosUI

// Type alias for backward compatibility
typealias ModernProfileEditView = ProfileEditView

struct ProfileEditView: View {
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProfileItem: PhotosPickerItem?
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var showSuccessAlert = false
    @State private var showCancelAlert = false
    @State private var showErrorAlert = false
    @State private var showValidationErrors = false
    @State private var showNetworkError = false
    
    // Error handling
    @StateObject private var errorHandler = ProfileErrorHandler.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    

    
    // Callback for data refresh after successful update
    var onProfileUpdated: (() -> Void)?
    
    init(user: User, onProfileUpdated: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(profile: user))
        self.onProfileUpdated = onProfileUpdated
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Profile and Cover Image Section
                Section {
                    ProfileImageEditRow(
                        selectedProfileItem: $selectedProfileItem,
                        selectedCoverItem: $selectedCoverItem,
                        viewModel: viewModel
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // Basic Information Section
                Section("基本情報") {
                    // Email Field
                    ProfileFormRow(
                        title: "メールアドレス",
                        text: $viewModel.email,
                        placeholder: "メールアドレスを入力してください",
                        validation: viewModel.emailValidation,
                        keyboardType: .emailAddress
                    )
                    
                    // Name Field
                    ProfileFormRow(
                        title: "名前",
                        text: $viewModel.name,
                        placeholder: "名前を入力してください",
                        validation: viewModel.nameValidation
                    )
                    
                    // Username Field with availability checking
                    VStack(alignment: .leading, spacing: 8) {
                        ProfileFormRow(
                            title: "ユーザーネーム",
                            text: $viewModel.username,
                            placeholder: "ユーザーネームを入力してください",
                            validation: viewModel.usernameValidation,
                            prefix: "@"
                        )
                        
                        // Username availability status
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
                                Image(systemName: viewModel.isUsernameAvailable == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(viewModel.isUsernameAvailable == true ? .green : .red)
                                    .font(.caption)
                                
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(viewModel.isUsernameAvailable == true ? .green : .red)
                            }
                        }
                    }
                }
                
                // Additional Information Section
                Section("追加情報") {
                    // Bio Field (Multi-line)
                    ProfileBioRow(
                        text: $viewModel.bio,
                        validation: viewModel.bioValidation
                    )
                    
                    // Location Field
                    ProfileFormRow(
                        title: "場所",
                        text: $viewModel.location,
                        placeholder: "場所を入力してください",
                        validation: viewModel.locationValidation
                    )
                    
                    // Website Field
                    ProfileFormRow(
                        title: "ウェブサイト",
                        text: $viewModel.website,
                        placeholder: "https://example.com",
                        validation: viewModel.websiteValidation,
                        keyboardType: .URL
                    )
                    
                    // Birthday Field
                    ProfileDatePickerRow(
                        title: "生年月日",
                        date: $viewModel.birthday
                    )
                }
                
                // Error Message Section
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
                        // Show loading indicator on save button when processing
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
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("保存されていない変更があります。本当に破棄しますか？")
            }
            .alert("エラー", isPresented: $errorHandler.showErrorAlert) {
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
            .onChange(of: selectedProfileItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.profileImage = uiImage
                        }
                    }
                }
            }
            .onChange(of: selectedCoverItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.coverImage = uiImage
                        }
                    }
                }
            }
            .overlay {
                // Loading overlay with enhanced feedback
                ProfileLoadingOverlay(
                    isLoading: viewModel.isProcessing,
                    message: getLoadingMessage()
                )
            }
            .overlay(alignment: .top) {
                // Network status banner
                NetworkStatusBanner()
            }
            .overlay {
                // Validation errors overlay
                if showValidationErrors && !viewModel.validationErrorMessages.isEmpty {
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
                // Success feedback overlay
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
                // Image upload progress indicators
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
    }
    
    // Form validation computed property
    private var isFormValid: Bool {
        return viewModel.isFormValid && networkMonitor.isConnected
    }
    
    // MARK: - Helper Methods
    
    private func handleCancelTapped() {
        if viewModel.hasUnsavedChanges {
            showCancelAlert = true
        } else {
            dismiss()
        }
    }
    
    private func handleSaveProfile() async {
        // Check network connectivity before saving
        guard networkMonitor.isConnected else {
            errorHandler.handleError(ProfileError.offlineError)
            return
        }
        
        await viewModel.updateProfile()
    }
    
    private func getLoadingMessage() -> String {
        if viewModel.isProfileImageUploading && viewModel.isCoverImageUploading {
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

// MARK: - Profile Form Row Components

struct ProfileFormRow: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let validation: ValidationResult
    var keyboardType: UIKeyboardType = .default
    var prefix: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack {
                if let prefix = prefix {
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

struct ProfileImageEditRow: View {
    @Binding var selectedProfileItem: PhotosPickerItem?
    @Binding var selectedCoverItem: PhotosPickerItem?
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover Image Section
            ZStack {
                // Cover Image
                if let coverImage = viewModel.coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                } else if let coverImageURL = viewModel.profile.coverImageURL, !coverImageURL.isEmpty {
                    AsyncImage(url: URL(string: coverImageURL)) { phase in
                        switch phase {
                        case .empty:
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.6),
                                    Color.purple.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipped()
                        case .failure:
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.6),
                                    Color.purple.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 120)
                        @unknown default:
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.6),
                                    Color.purple.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 120)
                        }
                    }
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.6),
                            Color.purple.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)
                }
                
                // Cover Image Edit Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        PhotosPicker(selection: $selectedCoverItem, matching: .images) {
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
                        .padding(12)
                    }
                }
            }
            
            // Profile Image Section
            HStack {
                ZStack(alignment: .bottomTrailing) {
                    // Profile Image
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
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 74, height: 74)
                                        .clipShape(Circle())
                                case .failure:
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                @unknown default:
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Profile Image Edit Button
                    PhotosPicker(selection: $selectedProfileItem, matching: .images) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .medium))
                            )
                    }
                    .offset(x: 4, y: 4)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, -40)
            .padding(.bottom, 16)
        }
    }
}


