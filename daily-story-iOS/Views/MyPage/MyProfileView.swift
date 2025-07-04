import SwiftUI

struct MyProfileView: View {
    @StateObject private var viewModel = ProfileViewModel(userID: 0) // ユーザーIDは適宜変更してください
    @State private var showingNewPost = false
    @State private var selectedTab = 0
    
    // カラー定数
    private let backgroundColor = Color(UIColor.systemBackground)
    private let cardBackground = Color.white
    private let accentColor = Color.blue
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // プロフィールヘッダー
                    ProfileHeaderView(user: viewModel.profile)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    
                    // タブセクション
                    TabSectionView(selectedTab: $selectedTab)
                    
                    // 投稿グリッド
                    PostGridView(stories: viewModel.stories)
                }
            }
            .background(backgroundColor)
            .navigationTitle(viewModel.profile.name ?? "プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingNewPost = true
                        }) {
                            Image(systemName: "plus.app")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            // メニュー表示
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
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
        .onAppear {
            // 画面表示時にプロフィールとストーリーを読み込む
            let userId = AuthService.shared.currentUser?.id ?? 0
            viewModel.loadProfile(userID: userId)
            viewModel.loadUserStories(userID: userId)
        }
        .refreshable {
            let userId = AuthService.shared.currentUser?.id ?? 0
            viewModel.loadProfile(userID: userId)
            viewModel.loadUserStories(userID: userId)
        }
    }
}

// プロフィールヘッダービュー
struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                // プロフィール画像
                if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray)
                        .frame(width: 90, height: 90)
                }
                
                // 統計情報
                HStack(spacing: 30) {
                    VStack(spacing: 4) {
//                        Text("\(user.postsCount ?? 0)")
//                            .font(.title2)
//                            .fontWeight(.bold)
                        Text("投稿")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(user.followersCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("フォロワー")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(user.followingCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("フォロー中")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // ユーザー情報
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(user.name ?? "")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                if let website = user.website, !website.isEmpty {
                    Text(website)
                        .font(.body)
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            
            // アクションボタン
            HStack(spacing: 8) {
                Button(action: {
                    // プロフィール編集画面へ
                }) {
                    Text("プロフィールを編集")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(6)
                }
                
                Button(action: {
                    // プロフィール共有
                }) {
                    Text("プロフィールをシェア")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(6)
                }
            }
        }
    }
}

// タブセクションビュー
struct TabSectionView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(spacing: 0) {
                TabButton(
                    icon: "grid",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                TabButton(
                    icon: "person.crop.square",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
}

struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .primary : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.primary : Color.clear)
                    .frame(height: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}

// 投稿グリッドビュー
struct PostGridView: View {
    let stories: [Story]
    
    let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        if stories.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "camera")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                    .padding(.top, 60)
                
                Text("投稿がありません")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("最初の投稿を作成して、友達と写真をシェアしましょう")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 40)
        } else {
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(stories) { story in
                    PostGridItemView(story: story)
                }
            }
        }
    }
}

struct PostGridItemView: View {
    let story: Story
    
    var body: some View {
//        if let imageURL = story.imageURL, let url = URL(string: imageURL) {
//            AsyncImage(url: url) { image in
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//            } placeholder: {
//                Rectangle()
//                    .fill(Color.gray.opacity(0.3))
//                    .overlay(
//                        ProgressView()
//                            .tint(.white)
//                    )
//            }
//            .aspectRatio(1, contentMode: .fit)
//            .clipped()
//            .onTapGesture {
//                // 投稿詳細を表示
//            }
//        } else {
//            Rectangle()
//                .fill(Color.gray.opacity(0.3))
//                .aspectRatio(1, contentMode: .fit)
//                .overlay(
//                    Image(systemName: "photo")
//                        .font(.title2)
//                        .foregroundColor(.white)
//                )
//                .onTapGesture {
//                    // 投稿詳細を表示
//                }
//        }
    }
}
