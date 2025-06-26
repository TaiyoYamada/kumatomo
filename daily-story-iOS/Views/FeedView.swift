import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = StoryViewModel()
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
                        ForEach(viewModel.stories) { story in
                            StoryCardView(story: story)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingNewPost = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("タイムライン")
            .sheet(isPresented: $showingNewPost) {
                PostView()
            }
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
            if viewModel.stories.isEmpty {
                await viewModel.fetchAllStories()
            }
        }
        .refreshable {
            await viewModel.fetchAllStories()
        }
    }
}

// Story Card View
struct StoryCardView: View {
    let story: Story
    
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: story.createdAt)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー（ユーザー情報）
            HStack(spacing: 10) {
                // ユーザーアイコン
                Image(systemName: mockAvatars[story.userId ?? 1] ?? "person.circle")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    // ユーザー名
                    Text(mockNames[story.userId ?? 1] ?? "ユーザー")
                        .font(.headline)
                    
                    // 投稿日時
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // 投稿内容
            Text(story.content)
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
