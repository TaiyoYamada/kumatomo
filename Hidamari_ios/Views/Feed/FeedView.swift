import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = PostViewModel()
    @State private var showingNewPost = false
    
    // カラー定数
    private let backgroundColor = Color(UIColor.systemGray6)
    private let cardBackground = Color.white
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.posts) { post in
                            PostCardView(post: post)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("タイムライン")
            .toolbarTitleDisplayMode(.inline)
//            .sheet(isPresented: $showingNewPost) {
//                PostView()
//            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                        )
                }
            }
            .overlay {
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                            .padding()
                        Spacer().frame(height: 100)
                    }
                }
            }
        }
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.fetchAllPosts()
            }
        }
        .refreshable {
            await viewModel.fetchAllPosts()
        }
    }
}

// Post Card View
struct PostCardView: View {
    let post: Post
    @State private var showingPostDetail = false
    
    // カラー定数
    private let cardBackground = Color.white
    

    
    // 日付フォーマッター
    private var formattedDate: String {
        guard let createdAt = post.createdAt else { return "" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }

    
    var body: some View {
        Button(action: { showingPostDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー（ユーザー情報）
                HStack(spacing: 10) {
                    // ユーザーアイコン
                    Image(systemName: "person.circle")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // ユーザー名
                        Text(post.user?.name ?? "ユーザー")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        // 投稿日時
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                // 投稿内容
                Text(post.content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 4)
                    .lineLimit(3)
                
                // 画像プレビュー（最適化された遅延読み込み）
                if let images = post.images, !images.isEmpty {
                    if images.count == 1 {
                        // 単一画像の場合
                        AsyncImage(url: URL(string: images.first!.imageUrl)) { imagePhase in
                            switch imagePhase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 150)
                                    .clipped()
                                    .cornerRadius(8)
                            case .failure(_):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 150)
                                    .cornerRadius(8)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .font(.system(size: 24))
                                            .foregroundStyle(.secondary)
                                    }
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 150)
                                    .cornerRadius(8)
                                    .overlay {
                                        ProgressView()
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        // 複数画像の場合は最初の3枚をプレビュー表示
                        HStack(spacing: 8) {
                            ForEach(Array(images.prefix(3).enumerated()), id: \.element.id) { index, image in
                                AsyncImage(url: URL(string: image.imageUrl)) { imagePhase in
                                    switch imagePhase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipped()
                                            .cornerRadius(8)
                                    case .failure(_):
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                    case .empty:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                            .overlay {
                                                ProgressView()
                                                    .scaleEffect(0.5)
                                            }
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .overlay(alignment: .bottomTrailing) {
                                    if index == 2 && images.count > 3 {
                                        Rectangle()
                                            .fill(Color.black.opacity(0.6))
                                            .cornerRadius(8)
                                            .overlay {
                                                Text("+\(images.count - 3)")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                            }
                                    }
                                }
                            }
                            Spacer()
                        }
                        .frame(height: 60)
                    }
                } else if let imageUrl = post.imageUrl {
                    // Backward compatibility for single image
                    AsyncImage(url: URL(string: imageUrl)) { imagePhase in
                        switch imagePhase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(8)
                        case .failure(_):
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 150)
                                .cornerRadius(8)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.secondary)
                                }
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 150)
                                .cornerRadius(8)
                                .overlay {
                                    ProgressView()
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // Shop info if available
                if let shop = post.shop {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        Text(shop.name)
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        Spacer()
                    }
                }
                
                // フッター（いいねやコメント数など）
                HStack(spacing: 20) {
                    // コメントボタン
                    Label("0", systemImage: "message")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // いいねボタン
                    Label("0", systemImage: "heart")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Multiple images indicator
                    if let images = post.images, images.count > 1 {
                        HStack(spacing: 2) {
                            Image(systemName: "photo.stack")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("\(images.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingPostDetail) {
            PostDetailView(post: post)
        }
    }
}
