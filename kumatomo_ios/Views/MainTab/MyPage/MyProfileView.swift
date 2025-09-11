import SwiftUI

struct MyProfileView: View {
    @StateObject private var viewModel = ProfileViewModel(userID: 0)
    @StateObject private var postviewModel = PostViewModel()
    @State private var showingNewPost = false
    @State private var selectedTab = 0
    @State private var sheetDestination: SheetDestination? = nil
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // カバー画像とプロフィール
                        ModernProfileHeaderView(
                            user: viewModel.profile,
                            scrollOffset: scrollOffset,
                            onEditTapped: {
                                sheetDestination = .profileEdit(viewModel.profile, onProfileUpdated: {
                                    // Refresh profile data after successful update
                                    let userId = AuthService.shared.currentUser?.id ?? 0
                                    viewModel.loadProfile(userID: userId)
                                    viewModel.loadUserPosts(userID: userId)
                                })
                            }
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
//                        ModernTabSectionView(selectedTab: $selectedTab)
                        
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
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchView()) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primary)
                    }
                }
            }
            .withSheetRouter(sheet: $sheetDestination)
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

struct ModernProfileHeaderView: View {
    let user: User
    let scrollOffset: CGFloat
    let onEditTapped: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack {
                    if let coverImageURL = user.coverImageURL, !coverImageURL.isEmpty, let url = URL(string: coverImageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.orange.opacity(0.7),
                                        Color.purple.opacity(0.7),
                                        Color.orange.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .overlay(
                                    ProgressView()
                                        .tint(.white.opacity(0.8))
                                )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(_):
                                // エラー時のデフォルトグラデーション
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.orange.opacity(0.7),
                                        Color.purple.opacity(0.7),
                                        Color.orange.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.7))
                                )
                            @unknown default:
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.orange.opacity(0.7),
                                        Color.purple.opacity(0.7),
                                        Color.orange.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                    } else {
                        // デフォルトのカバー画像
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.orange.opacity(0.7),
                                Color.purple.opacity(0.7),
                                Color.orange.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("カバー画像")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        )
                    }
                }
                .frame(height: min(220, UIScreen.main.bounds.height * 0.25)) // iPhone 16 最適化
                .clipped()
                .overlay(
                    // グラデーションオーバーレイ - より洗練された効果
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.clear, location: 0.0),
                            .init(color: Color.black.opacity(0.1), location: 0.7),
                            .init(color: Color.black.opacity(0.3), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // プロフィール画像とボタンエリア - Twitter/Instagram レイアウト
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .top) {
                        // プロフィール画像 - より大きく、より目立つように
                        ZStack {
                            // 外側の白い境界線
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 108, height: 108)
                                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                            
                            // 内側のプロフィール画像
                            if let imageURL = user.profileImageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                ProgressView()
                                                    .tint(.secondary)
                                            )
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure(_):
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 42))
                                                    .foregroundColor(.secondary)
                                            )
                                    @unknown default:
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 42))
                                                    .foregroundColor(.secondary)
                                            )
                                    }
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 42))
                                            .foregroundColor(.secondary)
                                    )
                                    .frame(width: 100, height: 100)
                            }
                        }
                        .offset(y: -54)
                        
                        Spacer()
                    }
                    
                    // 編集ボタン - Twitter/Instagram スタイル
                    Button(action: {
                        onEditTapped()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                            Text("プロフィールを編集")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
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

// モダンなプロフィール情報 - Twitter/Instagram スタイル
struct ModernProfileInfoView: View {
    let user: User
    
    private func formatJoinDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.name ?? "名前未設定")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    if user.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                    }
                }
                
                if let username = user.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                } else {
                    Text("@username")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.6))
                        .fontWeight(.medium)
                }
            }
            
            // バイオ/自己紹介
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            
            // 詳細情報 - Twitter/Instagram スタイルのアイコン付き情報
            VStack(alignment: .leading, spacing: 12) {
                // 場所情報
                if let location = user.location, !location.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "location")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 参加日 - より詳細な表示
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    
                    Group {
                        if let joinedDate = user.joinedDate, !joinedDate.isEmpty {
                            Text("\(joinedDate)に参加")
                        } else if let createdAt = user.createdAt {
                            Text("\(formatJoinDate(createdAt))に参加")
                        } else {
                            Text("参加日不明")
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 統計情報ビュー - Twitter/Instagram スタイル
struct ProfileStatsView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 0) {
            // 投稿数
            StatItemView(
                count: user.postCount ?? 0,
                label: "投稿",
                isClickable: false
            )
            
            Spacer()
            
            // フォロー中
            StatItemView(
                count: user.followingCount ?? 0,
                label: "フォロー中",
                isClickable: true
            )
            
            Spacer()
            
            // フォロワー
            StatItemView(
                count: user.followersCount ?? 0,
                label: "フォロワー",
                isClickable: true
            )
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct StatItemView: View {
    let count: Int
    let label: String
    let isClickable: Bool
    
    private var formattedCount: String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
    
    var body: some View {
        Button(action: {
            if isClickable {
                // TODO: フォロー/フォロワー一覧画面への遷移
                print("Navigate to \(label) list")
            }
        }) {
            HStack(spacing: 4) {
                Text(formattedCount)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
        }
        .disabled(!isClickable)
        .buttonStyle(PlainButtonStyle())
    }
}

// モダンなタブセクション
//struct ModernTabSectionView: View {
//    @Binding var selectedTab: Int
//    
//    let tabs = ["投稿", "メディア", "いいね"]
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 0) {
//                    ForEach(0..<tabs.count, id: \.self) { index in
//                        Button(action: {
//                            withAnimation(.easeInOut(duration: 0.3)) {
//                                selectedTab = index
//                            }
//                        }) {
//                            VStack(spacing: 12) {
//                                Text(tabs[index])
//                                    .font(.system(size: 16, weight: .semibold))
//                                    .foregroundColor(selectedTab == index ? .primary : .secondary)
//                                
//                                Rectangle()
//                                    .fill(selectedTab == index ? Color.accentColor : Color.clear)
//                                    .frame(height: 3)
//                                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                    }
//                }
//                .padding(.horizontal, 20)
//            }
//            
//            Divider()
//                .background(Color.secondary.opacity(0.3))
//        }
//        .background(.regularMaterial)
//    }
//}

// モダンな投稿タイムライン - Twitter/Instagram スタイル
struct ModernPostGridView: View {
    let posts: [Post]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            if posts.isEmpty {
                EmptyStateView()
            } else {
                ForEach(posts) { post in
                    ModernPostCardView(post: post)
                        .padding(.vertical, 2)
                    
                    Divider()
                        .background(Color.secondary.opacity(0.15))
                        .padding(.leading, 20)
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

// 空の状態ビュー - Twitter/Instagram スタイル
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            // アイコン
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }
            
            // メッセージ
            VStack(spacing: 8) {
                Text("まだ投稿がありません")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("あなたの最初の投稿を共有して、\nフォロワーとつながりましょう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, 80)
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }
}

// 投稿カード - Twitter/Instagram スタイル
struct ModernPostCardView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PostCardHeaderView(post: post)
            PostCardContentView(post: post)
            PostCardActionsView(post: post)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// 投稿カードヘッダー - Twitter/Instagram スタイル
struct PostCardHeaderView: View {
    let post: Post
    
    private var timeAgoText: String {
        guard let createdAt = post.createdAt else { return "不明" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)
        
        if timeInterval < 60 {
            return "今"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)時間"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)日"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PostUserImageView(imageURL: post.user?.profileImageURL)
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(post.user?.name ?? "Unknown User")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if post.user?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                    }
                }
                
                HStack(spacing: 4) {
                    Text("@\(post.user?.username ?? "username")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("·")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(timeAgoText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                // TODO: 投稿メニューの表示
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// 投稿カードコンテンツ - Twitter/Instagram スタイル
struct PostCardContentView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 投稿テキスト
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            
            // 画像グリッド
            if let images = post.images, !images.isEmpty {
                PostImagesGridView(images: images.map { $0.imageUrl })
                    .cornerRadius(16)
            }
            
            // タグ表示
            if let tags = post.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange.opacity(0.1))
                                )
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(.leading, 56)
    }
}

// 投稿カードアクション - Twitter/Instagram スタイル
struct PostCardActionsView: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 0) {
            // コメント
            ActionButton(
                icon: "message",
                count: post.commentCount ?? 0,
                color: .secondary,
                activeColor: .orange
            )
            
            Spacer()
            
            // リツイート/シェア
            ActionButton(
                icon: "arrow.2.squarepath",
                count: 0, // TODO: リツイート数を追加
                color: .secondary,
                activeColor: .green
            )
            
            Spacer()
            
            // いいね
            ActionButton(
                icon: post.userReaction == .thumbsUp ? "heart.fill" : "heart",
                count: post.reactions?.thumbsUp ?? 0,
                color: post.userReaction == .thumbsUp ? .red : .secondary,
                activeColor: .red
            )
            
            Spacer()
            
            // シェア
            Button(action: {
                // TODO: シェア機能の実装
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .padding(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(.leading, 56)
        .padding(.top, 12)
    }
}


