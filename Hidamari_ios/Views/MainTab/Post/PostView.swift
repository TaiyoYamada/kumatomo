import SwiftUI
import PhotosUI

struct PostView: View {
    @StateObject private var viewModel = PostViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main content area
                ScrollView {
                    VStack(spacing: 16) {
                        // User profile and text input section
                        HStack(alignment: .top, spacing: 12) {
                            // User profile icon (top-left)
                            UserProfileIcon()
                            
                            // Text input area (center)
                            VStack(alignment: .leading, spacing: 12) {
                                TextInputArea(
                                    content: $viewModel.postContent,
                                    characterCount: viewModel.postContent.count
                                )
                                
                                // Image preview if images are selected
                                if !viewModel.selectedImages.isEmpty {
                                    ImagePreviewSection(
                                        selectedImages: $viewModel.selectedImages,
                                        selectedItems: $selectedItems
                                    )
                                }
                                
                                // Shop selection if shop is selected
                                if viewModel.selectedShop != nil {
                                    ShopPreviewSection(selectedShop: $viewModel.selectedShop)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        Spacer(minLength: 100) // Space for action buttons
                    }
                }
                
                // Action buttons row (bottom)
                ActionButtonsRow(
                    selectedImages: $viewModel.selectedImages,
                    selectedItems: $selectedItems,
                    selectedShop: $viewModel.selectedShop
                )
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        viewModel.resetForm()
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("投稿") {
                        handlePost()
                    }
                    .disabled(!canPost)
                    .foregroundColor(canPost ? .blue : .secondary)
                    .fontWeight(.semibold)
                }
            }
        }
        .overlay {
            OverlayContent(viewModel: viewModel) {
                dismiss()
            }
        }
        .onChange(of: selectedItems) { newItems in
            handleMultipleImageSelection(newItems)
        }
    }
}

// MARK: - Computed Properties
private extension PostView {
    var canPost: Bool {
        // Updated validation: require text OR images (not both), and at least one tag
        let hasContent = (!viewModel.postContent.isEmpty && viewModel.postContent.count <= 500) || !viewModel.selectedImages.isEmpty
        let hasTags = !viewModel.selectedTags.isEmpty
        return hasContent && hasTags && !viewModel.isLoading
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
                
                if success {
                    await MainActor.run {
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
// MARK: - User Profile Icon
private struct UserProfileIcon: View {
    var body: some View {
        AsyncImage(url: URL(string: AuthService.shared.currentUser?.profileImageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.gray)
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Text Input Area
private struct TextInputArea: View {
    @Binding var content: String
    let characterCount: Int
    
    private var isOverLimit: Bool {
        characterCount > 500
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $content)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .overlay(
                    Group {
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
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                        }
                    }
                )
            
            // Character counter
            HStack {
                Spacer()
                Text("\(characterCount)/500")
                    .font(.caption)
                    .foregroundColor(isOverLimit ? .red : .secondary)
            }
        }
    }
}

// MARK: - Image Preview Section
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

// MARK: - Shop Preview Section
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

// MARK: - Action Buttons Row
private struct ActionButtonsRow: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedShop: Shop?
    @State private var showingShopPicker = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Image attachment button
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            // Shop selection button
            Button(action: { showingShopPicker = true }) {
                Image(systemName: "location")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            // Emoji button (placeholder for future implementation)
            Button(action: {}) {
                Image(systemName: "face.smiling")
                    .font(.title2)
                    .foregroundColor(.blue)
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
        }
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
