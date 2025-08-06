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
    
    // カラー定数
    private let cardBackground = Color.white
    
    // モック用アバター画像とユーザー名マッピング
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
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー（ユーザー情報）
            HStack(spacing: 10) {
                // ユーザーアイコン
                Image(systemName: mockAvatars[post.userId ?? 1] ?? "person.circle")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    // ユーザー名
                    Text(mockNames[post.userId ?? 1] ?? "ユーザー")
                        .font(.headline)
                    
                    // 投稿日時
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // 投稿内容
            Text(post.content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
            
            // フッター（いいねやコメント数など）
            HStack(spacing: 20) {
                // コメントボタン
                Label("0", systemImage: "message")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // いいねボタン
                Label("0", systemImage: "heart")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
