import SwiftUI
import PhotosUI

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

                    if viewModel.selectedShop != nil {
                        ShopPreviewSection(selectedShop: $viewModel.selectedShop)
                    }
                }

                ActionButtonsRow(
                    selectedImages: $viewModel.selectedImages,
                    selectedItems: $selectedItems,
                    selectedShop: $viewModel.selectedShop,
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
                                .foregroundColor(.orange)
                                .scaleEffect(0.8)
                        } else if canPost {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .scaleEffect(0.8)
                        }

                        Button("投稿") {
                            handlePost()
                        }
                        .disabled(!canPost)
                        .foregroundColor(canPost ? .orange : .gray)
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
                Button("キャンセル", role: .cancel) { }
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
            if viewModel.postContent.isEmpty &&
                viewModel.selectedImages.isEmpty &&
                viewModel.selectedShop == nil &&
                viewModel.selectedTags == ["熊本県全体"] {
            }
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
        viewModel.selectedShop != nil ||
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
        case .failure(let error):
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
                    shopId: viewModel.selectedShop?.id,
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
            return .orange
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
                            isNearLimit ? .orange :
                            isWarningLimit ? .yellow : .orange
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
                            .foregroundColor(.orange)
                    }

                    Text("\(characterCount)")
                        .font(.caption)
                        .fontWeight(isOverLimit || isNearLimit ? .semibold : .regular)
                        .foregroundColor(
                            isOverLimit ? .red :
                            isNearLimit ? .orange :
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
                            isNearLimit ? Color.orange.opacity(0.1) :
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
                        .foregroundColor(.orange)

                    Text("文字数制限まであと\(300 - characterCount)文字です。")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
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

private struct ImagePreviewSection: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedItems: [PhotosPickerItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(12)

                        Button(action: {
                            selectedImages.remove(at: index)
                            if selectedItems.indices.contains(index) {
                                selectedItems.remove(at: index)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .offset(x: 8, y: -8)
                    }
                }
            }
        }
    }
}

private struct ShopPreviewSection: View {
    @Binding var selectedShop: Shop?

    var body: some View {
        if let shop = selectedShop {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shop.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    if let address = shop.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button(action: { selectedShop = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

private struct ActionButtonsRow: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedShop: Shop?
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    @State private var showingShopPicker = false
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
                    .foregroundColor(.orange)
            }

            Button(action: { showingShopPicker = true }) {
                Image(systemName: "location")
                    .font(.title2)
                    .foregroundColor(.orange)
            }

            Button(action: { showingRegionalTagPicker = true }) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundColor(.orange)
            }

            Button(action: {}) {
                Image(systemName: "face.smiling")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            .disabled(true)
            .opacity(0.5)

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
        .sheet(isPresented: $showingShopPicker) {
            ShopPickerView(selectedShop: $selectedShop)
                .appSheetStyle()
        }
        .sheet(isPresented: $showingRegionalTagPicker) {
            RegionalTagSelectionView(
                selectedTags: $selectedTags,
                availableTags: availableTags
            )
            .appSheetStyle()
        }
    }
}



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
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.orange)
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
                    .tint(Color.orange)
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

