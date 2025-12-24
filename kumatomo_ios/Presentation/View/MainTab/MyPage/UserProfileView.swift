import SwiftUI
import Factory

// MARK: - UserProfileView

struct UserProfileView: View {
    let userId: Int
    @Environment(CurrentUserManager.self) private var userManager
    @Environment(AppRouter.self) private var appRouter
    @State private var viewModel: ProfileViewModel
    @State private var bulletinBoardViewModel = BulletinBoardViewModel()
    @State private var followViewModel = FollowViewModel()
    @State private var selectedTab: ProfileTab = .posts
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
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.errorMessage != nil {
                    errorView
                } else {
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

    // MARK: - Profile Header Section

    private var profileHeaderSection: some View {
        VStack(spacing: 0) {
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
                    viewModel.loadMoreUserPosts(userID: userId)
                }
            )
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
        guard !isCurrentUser else { return }
        do {
            let service = Container.shared.userAPIService()
            let status = try await service.fetchFollowStatus(userId: userId)
            isFollowing = status.isFollowing
        } catch {
            // フォロー状態取得に失敗した場合は false を設定
            isFollowing = false
        }
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

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileView(userId: 1)
            .environment(CurrentUserManager.shared)
            .environment(AppRouter.shared)
    }
}
