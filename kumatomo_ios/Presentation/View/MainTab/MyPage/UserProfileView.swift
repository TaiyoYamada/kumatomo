import SwiftUI
import Factory

// MARK: - UserProfileView

/// 他ユーザーのプロフィール表示View
/// MyProfileViewと同様のモダンUIを採用
struct UserProfileView: View {
    let userId: Int
    @Environment(CurrentUserManager.self) private var userManager
    @Environment(AppRouter.self) private var appRouter
    @State private var viewModel: ProfileViewModel
    @State private var bulletinBoardViewModel = BulletinBoardViewModel()
    @State private var followViewModel = FollowViewModel()
    @State private var isFollowing = false
    @State private var showingFollowers = false
    @State private var showingFollowing = false

    private var isCurrentUser: Bool {
        userManager.currentUser?.id == userId
    }

    init(userId: Int) {
        self.userId = userId
        _viewModel = State(initialValue: ProfileViewModel(userID: userId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.errorMessage != nil {
                    errorView
                } else {
                    // カバー画像とプロフィール
                    UserProfileHeaderView(
                        user: viewModel.profile,
                        isFollowing: isFollowing,
                        isFollowLoading: followViewModel.isFollowActionInProgress,
                        isCurrentUser: isCurrentUser,
                        onFollowTapped: {
                            Task {
                                isFollowing = await followViewModel.toggleFollow(
                                    userId: userId,
                                    isCurrentlyFollowing: isFollowing
                                )
                            }
                        }
                    )

                    // プロフィール情報
                    ModernProfileInfoView(user: viewModel.profile)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // 統計情報
                    UserProfileStatsView(
                        user: viewModel.profile,
                        onFollowersTapped: { showingFollowers = true },
                        onFollowingTapped: { showingFollowing = true }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // 区切り線
                    Rectangle()
                        .fill(Color(UIColor.separator))
                        .frame(height: 1)

                    // 投稿タイムライン
                    PostTimeline(
                        posts: viewModel.posts,
                        loading: viewModel.isLoadingMore,
                        onRefresh: {},
                        onLoadMore: {
                            viewModel.loadMoreUserPosts(userID: userId)
                        },
                        embedInScrollView: false,
                        onToggleLike: { post in
                            await handleToggleLike(post: post)
                        }
                    )
                    .environment(bulletinBoardViewModel)
                }
            }
        }
        .refreshable {
            viewModel.loadProfile(userID: userId)
            viewModel.loadUserPosts(userID: userId)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFollowers) {
            FollowersListView(userId: userId, userName: viewModel.profile.name)
        }
        .sheet(isPresented: $showingFollowing) {
            FollowingListView(userId: userId, userName: viewModel.profile.name)
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
        .task {
            await loadFollowStatus()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("読み込み中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("エラーが発生しました")
                .font(.title2)
                .fontWeight(.semibold)

            Text(viewModel.errorMessage ?? "不明なエラー")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("再試行") {
                viewModel.loadProfile(userID: userId)
                viewModel.loadUserPosts(userID: userId)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
        .padding(.horizontal)
    }

    // MARK: - Private Methods

    private func loadFollowStatus() async {
        // TODO: APIからフォロー状態を取得
        isFollowing = false
    }

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

// MARK: - UserProfileHeaderView

/// 他ユーザー用のプロフィールヘッダー
/// MyProfileViewのModernProfileHeaderViewと同様のデザインで、編集ボタンの代わりにフォローボタンを表示
struct UserProfileHeaderView: View {
    let user: User
    let isFollowing: Bool
    let isFollowLoading: Bool
    let isCurrentUser: Bool
    let onFollowTapped: () -> Void

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                // カバー画像
                ZStack {
                    if let coverImageURL = user.coverImageURL, !coverImageURL.isEmpty,
                       let url = URL(string: coverImageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                defaultCoverGradient
                                    .overlay(
                                        ProgressView()
                                            .tint(.white.opacity(0.8))
                                    )
                            case let .success(image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                defaultCoverGradient
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 32))
                                            .foregroundColor(.white.opacity(0.7))
                                    )
                            @unknown default:
                                defaultCoverGradient
                            }
                        }
                    } else {
                        defaultCoverGradient
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
                .frame(height: min(220, UIScreen.main.bounds.height * 0.25))
                .clipped()
                .overlay(
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

                // プロフィール画像とフォローボタン
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .top) {
                        // プロフィール画像
                        ZStack {
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 108, height: 108)
                                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

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
                                        defaultProfileImage
                                    @unknown default:
                                        defaultProfileImage
                                    }
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                defaultProfileImage
                                    .frame(width: 100, height: 100)
                            }
                        }
                        .offset(y: -54)

                        Spacer()
                    }

                    // フォローボタン（自分以外の場合のみ表示）
                    if !isCurrentUser {
                        FollowButton(
                            isFollowing: isFollowing,
                            isLoading: isFollowLoading,
                            onTap: onFollowTapped
                        )
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 300)
    }

    private var defaultCoverGradient: some View {
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

    private var defaultProfileImage: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.secondary)
            )
    }
}

// MARK: - UserProfileStatsView

/// 他ユーザー用の統計情報表示
/// タップでフォロワー・フォロー中一覧を表示
struct UserProfileStatsView: View {
    let user: User
    let onFollowersTapped: () -> Void
    let onFollowingTapped: () -> Void

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
            Button(action: onFollowingTapped) {
                StatItemView(
                    count: user.followingCount ?? 0,
                    label: "フォロー中",
                    isClickable: true
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // フォロワー
            Button(action: onFollowersTapped) {
                StatItemView(
                    count: user.followersCount ?? 0,
                    label: "フォロワー",
                    isClickable: true
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileView(userId: 1)
            .environment(CurrentUserManager.shared)
            .environment(AppRouter.shared)
    }
}
