import SwiftUI
import PhotosUI

/// A Twitter-style comment composition interface
struct CommentComposeView: View {
    @ObservedObject var viewModel: CommentViewModel
    let onSubmit: () async -> Void
    
    // MARK: - State Properties
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showImagePicker = false
    @State private var textFieldHeight: CGFloat = 40
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Constants
    
    private let maxTextFieldHeight: CGFloat = 120
    private let minTextFieldHeight: CGFloat = 40
    private let profileImageSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            // Main compose area
            HStack(alignment: .top, spacing: 12) {
                // User profile image
                profileImageView
                
                // Content area
                VStack(spacing: 12) {
                    // Text input area
                    textInputArea
                    
                    // Selected image preview
                    if let selectedImage = viewModel.selectedImage {
                        selectedImagePreview(selectedImage)
                    }
                    
                    // Action buttons row
                    actionButtonsRow
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                errorMessageView(errorMessage)
            }
            
            // Success message
            if viewModel.showSuccessMessage {
                successMessageView
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onChange(of: selectedPhotoItem) { _, newItem in
            handlePhotoSelection(newItem)
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            if isTextFieldFocused {
                isTextFieldFocused = false
            }
        }
    }
    
    // MARK: - Profile Image View
    
    private var profileImageView: some View {
        AsyncImage(url: URL(string: CurrentUserManager.shared.currentUser?.profileImageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                )
        }
        .frame(width: profileImageSize, height: profileImageSize)
        .clipShape(Circle())
        .accessibilityLabel("プロフィール画像")
    }
    
    // MARK: - Text Input Area
    
    private var textInputArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text field with dynamic height
            ZStack(alignment: .topLeading) {
                // Background for proper sizing
                Text(viewModel.commentText.isEmpty ? "コメントを追加..." : viewModel.commentText)
                    .font(.system(size: 16))
                    .foregroundColor(.clear)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    updateTextFieldHeight(geometry.size.height)
                                }
                                .onChange(of: viewModel.commentText) { _, _ in
                                    updateTextFieldHeight(geometry.size.height)
                                }
                        }
                    )
                
                // Actual text field
                TextField("コメントを追加...", text: $viewModel.commentText, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .focused($isTextFieldFocused)
                    .lineLimit(1...6)
                    .onChange(of: viewModel.commentText) { _, newText in
                        viewModel.handleTextChange(newText)
                    }
                    .accessibilityLabel("コメント入力")
                    .accessibilityHint("コメントを入力してください")
            }
            .frame(height: max(minTextFieldHeight, min(textFieldHeight, maxTextFieldHeight)))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isTextFieldFocused ? Color.primaryOrange : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            
            // Character count and validation
            characterCountView
        }
    }
    
    // MARK: - Character Count View
    
    private var characterCountView: some View {
        HStack {
            // Validation status indicator
            if viewModel.isValidating {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("確認中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let validationError = viewModel.validationError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(validationError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Character count
            if !viewModel.characterCountText.isEmpty {
                Text(viewModel.characterCountText)
                    .font(.caption)
                    .foregroundColor(viewModel.characterCountColor)
                    .accessibilityLabel("文字数: \(viewModel.characterCount)")
            }
        }
    }
    
    // MARK: - Selected Image Preview
    
    private func selectedImagePreview(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("添付画像")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("削除") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.removeSelectedImage()
                    }
                }
                .font(.caption)
                .foregroundColor(.red)
                .accessibilityLabel("画像を削除")
            }
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .accessibilityLabel("選択された画像")
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Action Buttons Row
    
    private var actionButtonsRow: some View {
        HStack(spacing: 16) {
            // Image picker button
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel("画像を選択")
            .accessibilityHint("フォトライブラリから画像を選択します")
            
            Spacer()
            
            // Submit button
            submitButton
        }
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        Button {
            Task {
                await handleSubmit()
            }
        } label: {
            HStack(spacing: 6) {
                if viewModel.isSubmitting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("投稿")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(submitButtonColor)
            )
        }
        .disabled(!viewModel.canSubmit)
        .opacity(viewModel.canSubmit ? 1.0 : 0.6)
        .accessibilityLabel(viewModel.isSubmitting ? "投稿中" : "コメントを投稿")
        .accessibilityHint("コメントを投稿します")
        .accessibilityAddTraits(.isButton)
    }
    
    private var submitButtonColor: Color {
        if viewModel.canSubmit {
            return .primaryOrange
        } else {
            return Color.gray
        }
    }
    
    // MARK: - Error Message View
    
    private func errorMessageView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Success Message View
    
    private var successMessageView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text(viewModel.successMessage)
                .font(.caption)
                .foregroundColor(.green)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Helper Methods
    
    private func updateTextFieldHeight(_ newHeight: CGFloat) {
        let calculatedHeight = max(minTextFieldHeight, min(newHeight, maxTextFieldHeight))
        if abs(textFieldHeight - calculatedHeight) > 1 {
            withAnimation(.easeInOut(duration: 0.1)) {
                textFieldHeight = calculatedHeight
            }
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.processSelectedImage(image)
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = "画像の読み込みに失敗しました"
                }
            }
        }
    }
    
    private func handleSubmit() async {
        // Dismiss keyboard
        isTextFieldFocused = false
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Call the submit handler
        await onSubmit()
    }
}

// MARK: - Keyboard Handling Extension

extension CommentComposeView {
    /// Handles keyboard appearance and dismissal
    private func handleKeyboardEvents() {
        // This would be implemented if we need custom keyboard handling
        // For now, SwiftUI's built-in keyboard handling is sufficient
    }
}

// MARK: - Preview

#Preview("Default State") {
    VStack {
        CommentComposeView(
            viewModel: CommentViewModel(),
            onSubmit: {
                print("Submit tapped")
            }
        )
        .padding()
        
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("With Content") {
    VStack {
        CommentComposeView(
            viewModel: {
                let vm = CommentViewModel()
                vm.commentText = "これはサンプルコメントです。長いテキストの場合の表示を確認するためのテストコメントです。"
                return vm
            }(),
            onSubmit: {
                print("Submit tapped")
            }
        )
        .padding()
        
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("With Error") {
    VStack {
        CommentComposeView(
            viewModel: {
                let vm = CommentViewModel()
                vm.commentText = String(repeating: "あ", count: 600) // Over limit
                vm.validateContent()
                return vm
            }(),
            onSubmit: {
                print("Submit tapped")
            }
        )
        .padding()
        
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Submitting") {
    VStack {
        CommentComposeView(
            viewModel: {
                let vm = CommentViewModel()
                vm.commentText = "送信中のコメント"
                vm.isSubmitting = true
                return vm
            }(),
            onSubmit: {
                print("Submit tapped")
            }
        )
        .padding()
        
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}