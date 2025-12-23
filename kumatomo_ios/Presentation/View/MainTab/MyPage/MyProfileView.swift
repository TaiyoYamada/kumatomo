import SwiftUI

// MARK: - MyProfileView

struct MyProfileView: View {
    @State private var viewModel = ProfileViewModel(userID: 0)
    @State private var postviewModel = PostViewModel()
    @State private var bulletinBoardViewModel = BulletinBoardViewModel()
    @State private var showingNewPost = false
    @State private var selectedTab: ProfileTab = .posts
    @State private var sheetDestination: SheetDestination?
    @State private var scrollOffset: CGFloat = 0
    @State private var showingFollowers = false
    @State private var showingFollowing = false
    @Environment(\.openSidebar) private var openSidebar
    @Environment(CurrentUserManager.self) private var userManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // プロフィールヘッダーセクション
                profileHeaderSection

                // タブ付きコンテンツセクション
                Section {
                    tabContent
                } header: {
                    ProfileTabSelectorView(selectedTab: $selectedTab)
                }
            }
        }
        .refreshable {
            let userId = AuthService.shared.currentUser?.id ?? 0
            viewModel.loadProfile(userID: userId)
            viewModel.loadUserPosts(userID: userId)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sidebarButton()
        .withSheetRouter(sheet: $sheetDestination)
        .sheet(isPresented: $showingFollowers) {
            FollowersListView(userId: viewModel.profile.id, userName: viewModel.profile.name)
        }
        .sheet(isPresented: $showingFollowing) {
            FollowingListView(userId: viewModel.profile.id, userName: viewModel.profile.name)
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
        .onAppear {
            if let user = userManager.currentUser, user.id != 0 {
                viewModel.loadProfile(userID: user.id)
                viewModel.loadUserPosts(userID: user.id)
            }
        }
        .onChange(of: userManager.currentUser) { _, newUser in
            if let user = newUser, user.id != 0 {
                viewModel.loadProfile(userID: user.id)
                viewModel.loadUserPosts(userID: user.id)
            }
        }
    }

    // MARK: - Profile Header Section

    private var profileHeaderSection: some View {
        VStack(spacing: 0) {
            // カバー画像とプロフィール
            ModernProfileHeaderView(
                user: viewModel.profile,
                scrollOffset: 0,
                onEditTapped: {
                    sheetDestination = .profileEdit(viewModel.profile, onProfileUpdated: {
                        let userId = AuthService.shared.currentUser?.id ?? 0
                        viewModel.loadProfile(userID: userId)
                        viewModel.loadUserPosts(userID: userId)
                    })
                }
            )

            // プロフィール情報
            ModernProfileInfoView(user: viewModel.profile)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            // 統計情報（投稿数含む）
            ProfileStatsView(
                user: viewModel.profile,
                onFollowersTapped: { showingFollowers = true },
                onFollowingTapped: { showingFollowing = true }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .posts:
            PostTimeline(
                posts: viewModel.posts,
                loading: viewModel.isLoadingMore,
                onRefresh: {},
                onLoadMore: {
                    let userId = AuthService.shared.currentUser?.id ?? 0
                    viewModel.loadMoreUserPosts(userID: userId)
                },
                embedInScrollView: false,
                onToggleLike: { post in
                    await handleToggleLike(post: post)
                }
            )
            .environment(bulletinBoardViewModel)

        case .photos:
            ProfilePhotoGridView(
                posts: viewModel.posts,
                loading: viewModel.isLoadingMore,
                onLoadMore: {
                    let userId = AuthService.shared.currentUser?.id ?? 0
                    viewModel.loadMoreUserPosts(userID: userId)
                }
            )
        }
    }

    // MARK: - Like Toggle Handler

    private func handleToggleLike(post: Post) async {
        let postId = post.id
        let originalIsLiked = post.isLikedByCurrentUser ?? false
        let originalLikeCount = post.likeCount ?? 0

        await MainActor.run {
            if let idx = viewModel.posts.firstIndex(where: { $0.id == postId }) {
                var p = viewModel.posts[idx]
                let newIsLiked = !originalIsLiked
                let newLikeCount = originalIsLiked ? max(0, originalLikeCount - 1) : originalLikeCount + 1
                p.updateLikeStatus(isLiked: newIsLiked, likeCount: newLikeCount)
                viewModel.posts[idx] = p
            }
        }

        do {
            let response = try await EngagementAPIService.shared.toggleLike(postId: postId)
            await MainActor.run {
                if let idx = viewModel.posts.firstIndex(where: { $0.id == postId }) {
                    var p = viewModel.posts[idx]
                    p.updateLikeStatus(isLiked: response.isLiked, likeCount: response.likeCount)
                    viewModel.posts[idx] = p
                }
            }
        } catch {
            await MainActor.run {
                if let idx = viewModel.posts.firstIndex(where: { $0.id == postId }) {
                    var p = viewModel.posts[idx]
                    p.updateLikeStatus(isLiked: originalIsLiked, likeCount: originalLikeCount)
                    viewModel.posts[idx] = p
                }
            }
        }
    }
}

// MARK: - ModernProfileHeaderView

struct ModernProfileHeaderView: View {
    let user: User
    let scrollOffset: CGFloat
    let onEditTapped: () -> Void

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ZStack {
                    if let coverImageURL = user.coverImageURL, !coverImageURL.isEmpty,
                       let url = URL(string: coverImageURL) {
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
                            case let .success(image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
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
                        LinearGradient(
                            colors: [
                                Color(.systemGray5),
                                Color(.systemGray6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
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
                .frame(height: min(150, UIScreen.main.bounds.height * 0.18))
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

                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .top) {
                        // プロフィール画像 - より大きく、より目立つように
                        ZStack {
                            // 外側の白い境界線
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 90, height: 90)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

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
                                    case let .success(image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
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
                                .frame(width: 84, height: 84)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 42))
                                            .foregroundColor(.secondary)
                                    )
                                    .frame(width: 84, height: 84)
                            }
                        }
                        .offset(y: -45)

                        Spacer()
                    }

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
        .frame(height: 230)
    }
}

// MARK: - ModernProfileInfoView

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

            VStack(alignment: .leading, spacing: 12) {
                // 出身地情報
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

// MARK: - ProfileStatsView

struct ProfileStatsView: View {
    let user: User
    var onFollowersTapped: (() -> Void)?
    var onFollowingTapped: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            // 投稿数
            StatItemView(
                count: user.postCount ?? 0,
                label: "投稿",
                isClickable: false,
                labelColor: .primary
            )

            Spacer()

            // フォロー中
            Button(action: { onFollowingTapped?() }) {
                StatItemView(
                    count: user.followingCount ?? 0,
                    label: "フォロー中",
                    isClickable: false
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // フォロワー
            Button(action: { onFollowersTapped?() }) {
                StatItemView(
                    count: user.followersCount ?? 0,
                    label: "フォロワー",
                    isClickable: false
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - StatItemView

struct StatItemView: View {
    let count: Int
    let label: String
    let isClickable: Bool
    var labelColor: Color = .secondary

    private var formattedCount: String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }

    @ViewBuilder
    var body: some View {
        let content = HStack(spacing: 4) {
            Text(formattedCount)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(labelColor)
        }

        if isClickable {
            Button(action: {
                print("Navigate to \(label) list")
            }) {
                content
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            content
        }
    }
}

// MARK: - ModernPostGridView

// モダンなタブセクション

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

// MARK: - EmptyStateView

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

// MARK: - ModernPostCardView

struct ModernPostCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PostCardHeaderView(post: post)
            PostCardContentView(post: post)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// MARK: - PostCardHeaderView

struct PostCardHeaderView: View {
    let post: Post

    private var timeAgoText: String {
        guard let createdAt = post.createdAt else { return "不明" }

        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)

        if timeInterval < 60 {
            return "今"
        } else if timeInterval < 3_600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分"
        } else if timeInterval < 86_400 {
            let hours = Int(timeInterval / 3_600)
            return "\(hours)時間"
        } else {
            let days = Int(timeInterval / 86_400)
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

            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - PostCardContentView

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
                PostImagesGridView(imageUrls: images.map(\.imageUrl))
                    .cornerRadius(16)
            }

            // タグ表示（先頭に#、オレンジ、背景なし、折返し可）
            if let tags = post.tags, !tags.isEmpty {
                CategoryTagsView(tags: tags)
            }
        }
        .padding(.leading, 56)
    }
}
