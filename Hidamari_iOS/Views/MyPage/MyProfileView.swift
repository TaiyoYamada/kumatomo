import SwiftUI

struct MyProfileView: View {
    @StateObject private var viewModel = ProfileViewModel(userID: 0)
    @StateObject private var postviewModel = PostViewModel()
    @State private var showingNewPost = false
    @State private var selectedTab = 0
    @State private var showingEditProfile = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // カバー画像とプロフィール
                        ModernProfileHeaderView(
                            user: viewModel.profile,
                            showingEditProfile: $showingEditProfile,
                            scrollOffset: scrollOffset
                        )
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scroll")).minY)
                            }
                        )
                        
                        // プロフィール情報
                        ModernProfileInfoView(user: viewModel.profile)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        
                        // 統計情報
                        ProfileStatsView(user: viewModel.profile)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        
                        // タブセクション
                        ModernTabSectionView(selectedTab: $selectedTab)
                        
                        // 投稿グリッド
                        ModernPostGridView(posts: viewModel.posts)
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
                .background(Color(.systemBackground))
            }
            .navigationBarHidden(true)
            .overlay(alignment: .top) {
                // フローティングナビゲーションバー
                FloatingNavigationBar(
                    profileName: viewModel.profile.name ?? "プロフィール",
                    showingNewPost: $showingNewPost,
                    scrollOffset: scrollOffset
                )
            }
            .sheet(isPresented: $showingEditProfile) {
                ModernProfileEditView(user: viewModel.profile)
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
            let userId = AuthService.shared.currentUser?.id ?? 0
            viewModel.loadProfile(userID: userId)
            viewModel.loadUserPosts(userID: userId)
        }
        .refreshable {
            let userId = AuthService.shared.currentUser?.id ?? 0
            viewModel.loadProfile(userID: userId)
            viewModel.loadUserPosts(userID: userId)
        }
    }
}
// フローティングナビゲーションバー
struct FloatingNavigationBar: View {
    let profileName: String
    @Binding var showingNewPost: Bool
    let scrollOffset: CGFloat
    
    private var isVisible: Bool {
        scrollOffset > 100
    }
    
    var body: some View {
        HStack {
            Button(action: {
                // 戻る
            }) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            if isVisible {
                VStack(alignment: .leading, spacing: 2) {
                    Text(profileName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    showingNewPost = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    // メニュー
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .opacity(isVisible ? 1 : 0.9)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// モダンなプロフィールヘッダー
struct ModernProfileHeaderView: View {
    let user: User
    @Binding var showingEditProfile: Bool
    let scrollOffset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // カバー画像
                ZStack {
                    if let coverImageURL = user.coverImageURL, let url = URL(string: coverImageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.7),
                                    Color.purple.opacity(0.7),
                                    Color.pink.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.7),
                                Color.purple.opacity(0.7),
                                Color.pink.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(height: 220)
                .clipped()
                .overlay(
                    // グラデーションオーバーレイ
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.3)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // プロフィール画像とボタンエリア
                ZStack(alignment: .topTrailing) {
                    HStack {
                        // プロフィール画像
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                        .tint(.secondary)
                                }
                                .frame(width: 94, height: 94)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.secondary)
                                    .frame(width: 94, height: 94)
                            }
                        }
                        .offset(y: -50)
                        
                        Spacer()
                    }
                    
                    // 編集ボタン
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                            Text("編集")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            .ultraThinMaterial,
                            in: Capsule()
                        )
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 300)
    }
}

// モダンなプロフィール情報
struct ModernProfileInfoView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 名前とユーザーネーム
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.name ?? "名前")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if user.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
                
                if let username = user.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // バイオ
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 詳細情報
            VStack(alignment: .leading, spacing: 8) {
                if let location = user.location, !location.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "location")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let website = user.website, !website.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(website)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                if let joinedDate = user.joinedDate, !joinedDate.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("参加日: \(joinedDate)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 統計情報ビュー
struct ProfileStatsView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 32) {
            StatItemView(
                count: user.postCount ?? 0,
                label: "投稿"
            )
            
            StatItemView(
                count: user.followingCount ?? 0,
                label: "フォロー中"
            )
            
            StatItemView(
                count: user.followersCount ?? 0,
                label: "フォロワー"
            )
            
            Spacer()
        }
    }
}

struct StatItemView: View {
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// モダンなタブセクション
struct ModernTabSectionView: View {
    @Binding var selectedTab: Int
    
    let tabs = ["投稿", "メディア", "いいね"]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 12) {
                                Text(tabs[index])
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedTab == index ? .primary : .secondary)
                                
                                Rectangle()
                                    .fill(selectedTab == index ? Color.accentColor : Color.clear)
                                    .frame(height: 3)
                                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Divider()
                .background(Color.secondary.opacity(0.3))
        }
        .background(.regularMaterial)
    }
}

// モダンな投稿グリッド
struct ModernPostGridView: View {
    let posts: [Post]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            if posts.isEmpty {
                EmptyStateView()
            } else {
                ForEach(posts) { post in
                    ModernPostCardView(post: post)
                    
                    Divider()
                        .background(Color.secondary.opacity(0.2))
                }
            }
        }
    }
}

// 空の状態ビュー
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("まだ投稿がありません")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("最初の投稿をしてみましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
}

// モダンな投稿カード
struct ModernPostCardView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PostCardHeaderView(post: post)
            PostCardContentView(post: post)
            PostCardActionsView()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// 投稿カードヘッダー
struct PostCardHeaderView: View {
    let post: Post
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PostUserImageView(imageURL: post.user?.profileImageURL)
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(post.user?.name ?? "Unknown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("@\(post.user?.username ?? "username") · 2時間")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 投稿カードコンテンツ
struct PostCardContentView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post.content)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            if let images = post.images, !images.isEmpty {
                PostImagesGridView(images: images)
            }
        }
        .padding(.leading, 56)
    }
}

// 投稿カードアクション
struct PostCardActionsView: View {
    var body: some View {
        HStack(spacing: 0) {
            ActionButton(icon: "message", count: 12, color: .secondary)
            Spacer()
            ActionButton(icon: "arrow.2.squarepath", count: 5, color: .secondary)
            Spacer()
            ActionButton(icon: "heart", count: 24, color: .secondary)
            Spacer()
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.leading, 56)
        .padding(.top, 8)
    }
}

struct ActionButton: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 14))
                }
            }
            .foregroundColor(color)
        }
    }
}

// スクロールオフセット用のPreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
// 投稿ユーザー画像コンポーネント
struct PostUserImageView: View {
    let imageURL: String?
    
    var body: some View {
        AsyncImage(url: URL(string: imageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                )
        }
        .clipShape(Circle())
    }
}
// 投稿画像グリッドコンポーネント
struct PostImagesGridView: View {
    let images: [PostImage]
    
    private var displayImages: [PostImage] {
        Array(images.prefix(4))
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: min(displayImages.count, 2))
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 4) {
            ForEach(displayImages.indices, id: \.self) { index in
                PostImageItemView(imageURL: displayImages[index].imageUrl)
            }
        }
    }
}

// 投稿画像アイテムコンポーネント
struct PostImageItemView: View {
    let imageURL: String
    
    var body: some View {
        AsyncImage(url: URL(string: imageURL)) { loadedImage in
            loadedImage
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    ProgressView()
                        .tint(.secondary)
                )
        }
        .frame(height: 200)
        .clipped()
        .cornerRadius(12)
    }
}
