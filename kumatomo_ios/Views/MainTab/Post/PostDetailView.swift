import SwiftUI

struct PostDetailView: View {
    let post: Post
    @StateObject private var viewModel = PostViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var sheetDestination: SheetDestination?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Post Content Card
                        PostContentCard(post: post)
                        
                        // Images Section
                        if let images = post.images, !images.isEmpty {
                            PostImagesSection(images: images)
                        } else if let imageUrl = post.imageUrl {
                            // Backward compatibility for single image
                            LegacyImageSection(imageUrl: imageUrl)
                        }
                        
                        // Shop Information
                        if let shop = post.shop {
                            ShopInfoCard(shop: shop)
                        }
                        
                        // Tags Section
                        if let tags = post.tags, !tags.isEmpty {
                            TagsSection(tags: tags)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("投稿詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        dismiss()
                    }
                }
                
                if viewModel.isPostOwner(post) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                viewModel.startEditing(post)
                                sheetDestination = .postEdit(viewModel: viewModel)
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                viewModel.confirmDelete(post)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
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
        .alert("投稿を削除", isPresented: $viewModel.showDeleteConfirmation) {
            Button("削除", role: .destructive) {
                Task {
                    let success = await viewModel.deletePost()
                    if success {
                        dismiss()
                    }
                }
            }
            Button("キャンセル", role: .cancel) {
                viewModel.cancelDelete()
            }
        } message: {
            Text("この投稿を削除しますか？この操作は取り消せません。")
        }
    }
}

// MARK: - Post Content Card
private struct PostContentCard: View {
    let post: Post
    
    // Mock user data
    private let mockAvatars: [Int: String] = [
        1: "person.circle.fill",
        2: "person.circle",
        3: "person.crop.circle.fill",
        4: "person.crop.circle"
    ]
    
    private let mockNames: [Int: String] = [
        1: "山田太郎",
        2: "佐藤花子",
        3: "鈴木一郎",
        4: "田中めぐみ"
    ]
    
    private var formattedDate: String {
        guard let createdAt = post.createdAt else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User Header
            HStack(spacing: 12) {
                Image(systemName: mockAvatars[post.userId ?? 1] ?? "person.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mockNames[post.userId ?? 1] ?? "ユーザー")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Post Content
            Text(post.content)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
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

// MARK: - Post Images Section
private struct PostImagesSection: View {
    let images: [PostImage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("写真")
                .font(.headline.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(images.sorted(by: { ($0.displayOrder ?? 1) < ($1.displayOrder ?? 1) })) { image in
                        AsyncImage(url: URL(string: image.imageUrl)) { imagePhase in
                            switch imagePhase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 250, height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                            case .failure(_):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 250, height: 200)
                                    .cornerRadius(12)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.secondary)
                                    }
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 250, height: 200)
                                    .cornerRadius(12)
                                    .overlay {
                                        ProgressView()
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
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

// MARK: - Legacy Image Section
private struct LegacyImageSection: View {
    let imageUrl: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("写真")
                .font(.headline.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
            
            AsyncImage(url: URL(string: imageUrl)) { imagePhase in
                switch imagePhase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: 300)
                        .clipped()
                        .cornerRadius(12)
                case .failure(_):
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                        }
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay {
                            ProgressView()
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Shop Info Card
private struct ShopInfoCard: View {
    let shop: Shop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("お店情報")
                .font(.headline.weight(.medium))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(shop.name)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let address = shop.address {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let genre = shop.genre {
                    Text(genre)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                
                if let description = shop.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
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

// MARK: - Tags Section
private struct TagsSection: View {
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("タグ")
                .font(.headline.weight(.medium))
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
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
                SuccessOverlay(
                    message: viewModel.isDeleting ? "投稿を削除しました" : "投稿を更新しました",
                    onDismiss: onDismiss
                )
            }
            
            if viewModel.isLoading {
                LoadingOverlay(
                    message: viewModel.isDeleting ? "削除中..." : viewModel.isUpdating ? "更新中..." : "読み込み中..."
                )
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
    let message: String
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
                    
                    Text(message)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
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
                    onDismiss()
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
    let message: String
    
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: true)
    }
}
