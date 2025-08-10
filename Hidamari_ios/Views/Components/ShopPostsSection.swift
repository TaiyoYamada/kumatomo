import SwiftUI

struct ShopPostsSection: View {
    let posts: [Post]
    let isLoading: Bool
    let errorMessage: String?
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // セクションヘッダー
            HStack {
                Text("このお店の投稿")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                if !posts.isEmpty {
                    Text("\(posts.count)件")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if isLoading {
                // ローディング状態
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if let errorMessage = errorMessage {
                // エラー状態
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    
                    Text("投稿の読み込みに失敗しました")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("再試行") {
                        onRefresh()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.pink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            } else if posts.isEmpty {
                // 投稿がない状態
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    
                    Text("まだ投稿がありません")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("このお店での体験を最初に投稿してみませんか？")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            } else {
                // 投稿一覧
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        PostCard(post: post)
                    }
                }
            }
        }
    }
}

// MARK: - Post Card Component
struct PostCard: View {
    let post: Post
    @State private var selectedImageIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ユーザー情報
            HStack(spacing: 12) {
                // プロフィール画像
                AsyncImage(url: URL(string: post.user?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user?.name ?? "匿名ユーザー")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let createdAt = post.createdAt {
                        Text(formatDate(createdAt))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // 投稿内容
            Text(post.content)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            // 画像ギャラリー
            if let images = post.images, !images.isEmpty {
                PostImageGallery(images: images)
            } else if let imageUrl = post.imageUrl, !imageUrl.isEmpty {
                // 旧形式の単一画像対応
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            }
            
            // タグ表示
            if let tags = post.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.pink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.pink.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Post Image Gallery Component
struct PostImageGallery: View {
    let images: [PostImage]
    @State private var selectedImageIndex = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // メイン画像表示
            TabView(selection: $selectedImageIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    AsyncImage(url: URL(string: image.imageUrl)) { loadedImage in
                        loadedImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                ProgressView()
                            )
                    }
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 200)
            
            // 画像インジケーター（複数画像の場合のみ表示）
            if images.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == selectedImageIndex ? Color.pink : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedImageIndex = index
                                }
                            }
                    }
                }
                .padding(.top, 4)
            }
            
            // 画像カウンター（複数画像の場合のみ表示）
            if images.count > 1 {
                HStack {
                    Spacer()
                    Text("\(selectedImageIndex + 1) / \(images.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.trailing, 8)
                .padding(.top, -40)
            }
        }
    }
}
