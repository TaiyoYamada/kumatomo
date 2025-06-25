import SwiftUI

struct MyProfileView: View {
    @StateObject private var viewModel = StoryViewModel()
    @State private var showingNewPost = false
    
    // 仮のユーザーID（実際の実装では認証済みユーザーのIDを使用）
    private let currentUserId = 1
    
    // カラー定数
    private let backgroundColor = Color(UIColor.systemGray6)
    private let cardBackground = Color.white
    private let accentColor = Color.blue
    
    // モックユーザーデータ
    private var mockUser: User {
        return User(
            id: currentUserId,
            email: "yamada@example.com",
            name: "山田太郎",
            profileImageURL: nil,
            bio: "iOSエンジニア / 猫2匹と暮らしています",
            website: "https://example.com",
            followingCount: 120,
            followersCount: 145,
            createdAt: Date()
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // プロフィールヘッダー
                        ProfileHeaderView(user: mockUser)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        // 投稿セクションタイトル
                        HStack {
                            Text("投稿")
                                .font(.headline)
                                .padding(.leading)
                            Spacer()
                        }
                        
                        // 投稿一覧
                        if viewModel.userStories.isEmpty && !viewModel.isLoading {
                            VStack(spacing: 20) {
                                Image(systemName: "text.bubble")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                                
                                Text("投稿がありません")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    showingNewPost = true
                                }) {
                                    Text("最初の投稿を作成")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(accentColor)
                                        .cornerRadius(8)
                                }
                                .padding(.top, 10)
                            }
                            .padding(.top, 30)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.userStories) { story in
                                    StoryCardView(story: story)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                // 新規投稿ボタン
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
                                .background(accentColor)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("マイページ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 設定画面へ
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }
                }
            }
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
        }
        .task {
            if viewModel.userStories.isEmpty {
                await viewModel.fetchUserStories(userId: currentUserId)
            }
        }
        .refreshable {
            await viewModel.fetchUserStories(userId: currentUserId)
        }
    }
}

// プロフィールヘッダービュー
struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // プロフィール画像
                if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray)
                        .frame(width: 80, height: 80)
                }
                
                // ユーザー情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("@\(user.email.components(separatedBy: "@")[0])")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(user.bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            
            // フォロー情報
            HStack(spacing: 20) {
                VStack {
                    Text("\(user.followingCount)")
                        .font(.headline)
                    Text("フォロー中")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("\(user.followersCount)")
                        .font(.headline)
                    Text("フォロワー")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // プロフィール編集ボタン
                Button(action: {
                    // プロフィール編集画面へ
                }) {
                    Text("編集")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(20)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3)
    }
}

struct MyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        MyProfileView()
    }
}
