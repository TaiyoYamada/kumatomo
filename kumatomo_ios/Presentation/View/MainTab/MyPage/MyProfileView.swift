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
