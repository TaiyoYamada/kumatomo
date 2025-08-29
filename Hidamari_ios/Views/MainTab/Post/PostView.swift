import SwiftUI
import PhotosUI

struct PostView: View {
    @StateObject private var viewModel = PostViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var sheetDestination: SheetDestination?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Multiple Image Selection Section
                        ImageSelectionCard(
                            selectedImages: $viewModel.selectedImages,
                            selectedItems: $selectedItems
                        )
                        
                        // Shop Selection Section
                        ShopSelectionCard(
                            selectedShop: $viewModel.selectedShop,
                            onPickShop: {
                                sheetDestination = .shopPicker(selectedShop: $viewModel.selectedShop)
                            }
                        )
                        
                        // Content Input Section
                        ContentInputCard(
                            content: $viewModel.postContent,
                            characterCount: viewModel.postContent.count
                        )
                        
                        // Preview Button
                        PreviewButton(
                            isEnabled: canPreview,
                            onPreview: {
                                sheetDestination = .postPreview(
                                    content: viewModel.postContent,
                                    images: viewModel.selectedImages,
                                    shop: viewModel.selectedShop,
                                    onPost: {
                                        sheetDestination = nil
                                        handlePost()
                                    }
                                )
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    PostButton(
                        isEnabled: canPost,
                        isLoading: viewModel.isLoading
                    ) {
                        handlePost()
                    }
                }
            }
        }
        .overlay {
            OverlayContent(viewModel: viewModel) {
                dismiss()
            }
        }
        .withSheetRouter(sheet: $sheetDestination)
        .onChange(of: selectedItems) { newItems in
            handleMultipleImageSelection(newItems)
        }
    }
}

// MARK: - Computed Properties
private extension PostView {
    var canPost: Bool {
        !viewModel.postContent.isEmpty &&
        viewModel.postContent.count <= 500 &&
        !viewModel.selectedImages.isEmpty &&
        !viewModel.isLoading
    }
    
    var canPreview: Bool {
        !viewModel.postContent.isEmpty &&
        viewModel.postContent.count <= 500 &&
        !viewModel.selectedImages.isEmpty
    }
}

// MARK: - Actions
private extension PostView {
    func handlePost() {
        Task {
            if let currentUser = AuthService.shared.currentUser {
                let success = await viewModel.createPostWithMultipleImages(
                    userId: currentUser.id,
                    content: viewModel.postContent,
                    shopId: viewModel.selectedShop?.id,
                    images: viewModel.selectedImages
                )
            } else {
                viewModel.errorMessage = "ユーザー情報が取得できません。再ログインしてください。"
            }
        }
    }
    
    func handleMultipleImageSelection(_ newItems: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            
            for item in newItems.prefix(5) { // Maximum 5 images
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
// MARK: - Content Input Card
private struct ContentInputCard: View {
    @Binding var content: String
    let characterCount: Int
    
    private var isOverLimit: Bool {
        characterCount > 500
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("投稿内容")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("必須")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
            }
            
            TextEditor(text: $content)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.secondarySystemBackground))
                .frame(minHeight: 120)
                .cornerRadius(12)
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 1,
                    y: 1
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isOverLimit ? Color.red : Color.clear, lineWidth: 1)
                )
            
            CharacterCounter(
                count: characterCount,
                maxCount: 500,
                isOverLimit: isOverLimit
            )
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: .black.opacity(0.05),
            radius: 2,
            y: 1
        )
    }
}

// MARK: - Image Selection Card
private struct ImageSelectionCard: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedItems: [PhotosPickerItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("写真")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("必須")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
            }
            
            if selectedImages.isEmpty {
                PhotosPickerPlaceholder(selectedItems: $selectedItems)
            } else {
                ImagePreviewGrid(
                    selectedImages: $selectedImages,
                    selectedItems: $selectedItems
                )
            }
            
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("最大5枚まで選択できます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(selectedImages.count)/5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: .black.opacity(0.05),
            radius: 2,
            y: 1
        )
    }
}

// MARK: - Photos Picker Placeholder
private struct PhotosPickerPlaceholder: View {
    @Binding var selectedItems: [PhotosPickerItem]
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 5,
            matching: .images
        ) {
            VStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                
                Text("写真を選択")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text("タップして写真を追加してください")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
    }
}

// MARK: - Image Preview Grid
private struct ImagePreviewGrid: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedItems: [PhotosPickerItem]
    
    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    ImagePreviewCell(
                        image: image,
                        onRemove: {
                            selectedImages.remove(at: index)
                            if selectedItems.indices.contains(index) {
                                selectedItems.remove(at: index)
                            }
                        }
                    )
                }
                
                if selectedImages.count < 5 {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        AddImageCell()
                    }
                }
            }
        }
    }
}

// MARK: - Image Preview Cell
private struct ImagePreviewCell: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(8)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 8, y: -8)
        }
    }
}

// MARK: - Add Image Cell
private struct AddImageCell: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "plus")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
            
            Text("追加")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100, height: 100)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3]))
        )
    }
}

// MARK: - Shop Selection Card
private struct ShopSelectionCard: View {
    @Binding var selectedShop: Shop?
    let onPickShop: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("お店")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("任意")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary)
                    .cornerRadius(4)
            }
            
            Button(action: { onPickShop() }) {
                HStack {
                    if let shop = selectedShop {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shop.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            if let address = shop.address {
                                Text(address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            if let genre = shop.genre {
                                Text(genre)
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            
                            Text("お店を検索・選択")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if selectedShop != nil {
                        Button(action: { selectedShop = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("お店を選択すると、そのお店の詳細ページに投稿が表示されます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: .black.opacity(0.05),
            radius: 2,
            y: 1
        )
    }
}

// MARK: - Preview Button
private struct PreviewButton: View {
    let isEnabled: Bool
    let onPreview: () -> Void
    
    var body: some View {
        Button(action: { onPreview() }) {
            HStack {
                Image(systemName: "eye")
                    .font(.subheadline)
                
                Text("プレビュー")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isEnabled ? .blue : .secondary)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEnabled ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 16)
    }
}

// MARK: - Character Counter
private struct CharacterCounter: View {
    let count: Int
    let maxCount: Int
    let isOverLimit: Bool
    
    var body: some View {
        HStack {
            if isOverLimit {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.red)
                
                Text("文字数制限を超えています")
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }
            
            Spacer()
            
            Text("\(count)/\(maxCount)")
                .font(.caption)
                .foregroundStyle(isOverLimit ? Color.red : Color.secondary)
                .animation(.easeInOut(duration: 0.3), value: isOverLimit)
        }
    }
}

// MARK: - Post Button
private struct PostButton: View {
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button("投稿", action: action)
            .disabled(!isEnabled)
            .foregroundStyle(isEnabled ? Color.blue : Color.secondary)
            .opacity(isLoading ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isEnabled)
            .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - Overlay Content
private struct OverlayContent: View {
    @ObservedObject var viewModel: PostViewModel
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

// MARK: - Error Overlay
private struct ErrorOverlay: View {
    let message: String
    let onClose: () -> Void
    
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.red)
                    
                    Text(message)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("閉じる") {
                        onClose()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.red)
                }
                .padding(30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                .padding(.horizontal, 40)
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: message)
    }
}

// MARK: - Success Overlay
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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

// MARK: - Loading Overlay
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
