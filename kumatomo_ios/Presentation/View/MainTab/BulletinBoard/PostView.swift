import SwiftUI
import PhotosUI

// MARK: - PostView

struct PostView: View {
    let onPostSuccess: (() -> Void)?

    @State private var viewModel = PostViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingCancelAlert = false

    init(onPostSuccess: (() -> Void)? = nil) {
        self.onPostSuccess = onPostSuccess
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    TextInputArea(
                        content: $viewModel.postContent,
                        characterCount: viewModel.postContent.count
                    )

                    if !viewModel.selectedImages.isEmpty {
                        ImagePreviewSection(
                            selectedImages: $viewModel.selectedImages,
                            selectedItems: $selectedItems
                        )
                    }
                }

                ActionButtonsRow(
                    selectedImages: $viewModel.selectedImages,
                    selectedItems: $selectedItems,
                    selectedTags: $viewModel.selectedTags,
                    availableTags: viewModel.availableTags
                )

                TagSelectionView(
                    selectedTags: $viewModel.selectedTags,
                    availableTags: viewModel.availableTags
                )
                .padding(.top, 8)

            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        handleCancel()
                    }
                    .foregroundColor(.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        if !validationState.errors.isEmpty {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .scaleEffect(0.8)
                        } else if canPost {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .scaleEffect(0.8)
                        }

                        Button("投稿") {
                            handlePost()
                        }
                        .disabled(!canPost)
                        .foregroundColor(canPost ? .white : .gray)
                        .fontWeight(.semibold)
                        .opacity(canPost ? 1.0 : 0.6)
                    }
                    .animation(.easeInOut(duration: 0.2), value: canPost)
                    .animation(.easeInOut(duration: 0.2), value: validationState.errors.count)
                }
            }
            .alert("投稿を破棄しますか？", isPresented: $showingCancelAlert) {
                Button("破棄", role: .destructive) {
                    viewModel.resetForm()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("入力した内容は保存されません。")
            }
        }
        .overlay {
            OverlayContent(viewModel: viewModel) {
                onPostSuccess?()
                dismiss()
            }
        }
        .onChange(of: selectedItems) { newItems in
            handleMultipleImageSelection(newItems)
        }
        .onAppear {
            if viewModel.postContent.isEmpty,
               viewModel.selectedImages.isEmpty,
               viewModel.selectedTags == ["熊本県全体"] {}
        }
        .onDisappear {
            viewModel.errorMessage = nil
        }
    }
}

private extension PostView {
    var canPost: Bool {
        viewModel.canPost
    }

    var validationState: ValidationState {
        viewModel.getValidationState()
    }

    var hasUnsavedContent: Bool {
        !viewModel.postContent.isEmpty ||
            !viewModel.selectedImages.isEmpty ||
            viewModel.selectedTags != ["熊本県全体"]
    }
}

private extension PostView {
    func handleCancel() {
        if hasUnsavedContent {
            showingCancelAlert = true
        } else {
            viewModel.resetForm()
            dismiss()
        }
    }

    func handlePost() {
        let validation = viewModel.validateForSubmission()

        switch validation {
        case let .failure(error):
            viewModel.errorMessage = error.errorDescription
            return
        case .success:
            break
        }

        Task {
            if let currentUser = AuthService.shared.currentUser {
                let success = await viewModel.createPostWithMultipleImages(
                    userId: currentUser.id,
                    content: viewModel.postContent,
                    images: viewModel.selectedImages
                )

                if success {
                    await MainActor.run {
                        onPostSuccess?()
                        dismiss()
                    }
                }
            } else {
                viewModel.errorMessage = "ユーザー情報が取得できません。再ログインしてください。"
            }
        }
    }

    func handleMultipleImageSelection(_ newItems: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []

            for item in newItems.prefix(5) {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    images.append(uiImage)
                }
            }

            await MainActor.run {
                viewModel.selectedImages = images
            }
        }
    }
}

// MARK: - TextInputArea

private struct TextInputArea: View {
    @Binding var content: String
    let characterCount: Int

    private var isOverLimit: Bool {
        characterCount > 300
    }

    private var isNearLimit: Bool {
        characterCount > 270
    }

    private var isWarningLimit: Bool {
        characterCount > 220
    }

    private var borderColor: Color {
        if isOverLimit {
            return .red
        } else if isNearLimit {
            return .lightOrange
        } else if isWarningLimit {
            return .yellow
        } else {
            return Color(UIColor.separator).opacity(0.3)
        }
    }

    private var borderWidth: CGFloat {
        if isOverLimit || isNearLimit {
            return 2
        } else if isWarningLimit {
            return 1
        } else {
            return 0.5
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .animation(.easeInOut(duration: 0.2), value: characterCount)

                TextEditor(text: $content)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)

                if content.isEmpty {
                    VStack {
                        HStack {
                            Text("今何してる？")
                                .foregroundColor(.secondary)
                                .font(.body)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.leading, 12)
                    .allowsHitTesting(false)
                }
            }

            HStack(spacing: 8) {
                if characterCount > 0 {
                    ProgressView(value: Double(characterCount), total: 300.0)
                        .progressViewStyle(LinearProgressViewStyle(tint:
                            isOverLimit ? .red :
                                isNearLimit ? .lightOrange :
                                isWarningLimit ? .yellow : .lightOrange
                        ))
                        .frame(height: 2)
                        .animation(.easeInOut(duration: 0.2), value: characterCount)
                }

                Spacer()

                HStack(spacing: 4) {
                    if isOverLimit {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else if isNearLimit {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundColor(.lightOrange)
                    }

                    Text("\(characterCount)")
                        .font(.caption)
                        .fontWeight(isOverLimit || isNearLimit ? .semibold : .regular)
                        .foregroundColor(
                            isOverLimit ? .red :
                                isNearLimit ? .lightOrange :
                                isWarningLimit ? .yellow :
                                .secondary
                        )

                    Text("/300")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isOverLimit ? Color.red.opacity(0.1) :
                                isNearLimit ? Color.lightOrange.opacity(0.1) :
                                Color.clear
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: characterCount)
            }

            if isOverLimit {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)

                    Text("文字数制限を超えています。\(characterCount - 300)文字削除してください。")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.easeInOut(duration: 0.2), value: isOverLimit)
            } else if isNearLimit {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.lightOrange)

                    Text("文字数制限まであと\(300 - characterCount)文字です。")
                        .font(.caption)
                        .foregroundColor(.lightOrange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.lightOrange.opacity(0.1))
                .cornerRadius(6)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.easeInOut(duration: 0.2), value: isNearLimit)
            }
        }
    }
}

// MARK: - ImagePreviewSection

private struct ImagePreviewSection: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedItems: [PhotosPickerItem]

    @State private var previewingImageIndex: Int? = nil

    // カード寸法
    private let cardWidth: CGFloat = 140
    private let cardHeight: CGFloat = 180

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack(spacing: 8) {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.lightOrange, .lightOrange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("選択中の画像")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                // カウンターバッジ
                HStack(spacing: 4) {
                    Text("\(selectedImages.count)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("/")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text("5")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.lightOrange, .lightOrange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(.horizontal, 16)

            // 横スクロールカルーセル
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        ImageCardView(
                            image: image,
                            index: index,
                            onTap: {
                                previewingImageIndex = index
                            },
                            onDelete: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    selectedImages.remove(at: index)
                                    if selectedItems.indices.contains(index) {
                                        selectedItems.remove(at: index)
                                    }
                                }
                            }
                        )
                        .frame(width: cardWidth, height: cardHeight)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .fullScreenCover(item: $previewingImageIndex) { index in
            ImagePreviewSheet(image: selectedImages[index]) {
                previewingImageIndex = nil
            }
        }
    }
}

// MARK: - ImageCardView

private struct ImageCardView: View {
    let image: UIImage
    let index: Int
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // メイン画像カード
            Button(action: onTap) {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            }
            .buttonStyle(ImageCardButtonStyle())
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

            // インデックスバッジ（左下）
            VStack {
                Spacer()
                HStack {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                )
                        )
                        .padding(8)
                    Spacer()
                }
            }

            // 削除ボタン（右上、画像内に収める）
            Button(action: onDelete) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 28, height: 28)

                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 28, height: 28)

                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(DeleteButtonStyle())
            .padding(8)
        }
    }
}

// MARK: - ImageCardButtonStyle

private struct ImageCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - DeleteButtonStyle

private struct DeleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - PreviewImageButtonStyle

private struct PreviewImageButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - ImagePreviewSheet

private struct ImagePreviewSheet: View {
    let image: UIImage
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ZoomableImageView(image: image)

            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Int + @retroactive Identifiable

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

// MARK: - ActionButtonsRow

private struct ActionButtonsRow: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    @State private var showingRegionalTagPicker = false

    var body: some View {
        HStack(spacing: 20) {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.lightOrange)
            }

            Button(action: { showingRegionalTagPicker = true }) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundColor(.lightOrange)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(UIColor.separator)),
            alignment: .top
        )
        .sheet(isPresented: $showingRegionalTagPicker) {
            RegionalTagSelectionView(
                selectedTags: $selectedTags,
                availableTags: availableTags
            )
        }
    }
}

// MARK: - OverlayContent

private struct OverlayContent: View {
    @Bindable var viewModel: PostViewModel
    let onDismiss: () -> Void

    var body: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                ErrorOverlay(
                    message: errorMessage,
                    onClose: {
                        viewModel.errorMessage = nil
                    }
                )
            }

            if viewModel.showSuccessModal {
                SuccessOverlay(onDismiss: onDismiss)
            }

            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
}

// MARK: - ErrorOverlay

private struct ErrorOverlay: View {
    let message: String
    let onClose: () -> Void

    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.lightOrange.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.lightOrange)
                    }

                    VStack(spacing: 12) {
                        Text("投稿できません")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(message)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .padding(.horizontal)
                    }

                    Button("OK") {
                        onClose()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.lightOrange)
                }
                .padding(30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 40)
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: message)
    }
}

// MARK: - SuccessOverlay

private struct SuccessOverlay: View {
    let onDismiss: () -> Void
    @State private var checkmarkScale: CGFloat = 0

    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.green)
                            .scaleEffect(checkmarkScale)
                    }

                    VStack(spacing: 8) {
                        Text("投稿しました！")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("タイムラインに反映されます")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                .padding(.horizontal, 40)
            }
            .onAppear {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30).delay(0.1)) {
                    checkmarkScale = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        onDismiss()
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
    }
}

// MARK: - LoadingOverlay

private struct LoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)

                    Text("投稿中...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: true)
    }
}
