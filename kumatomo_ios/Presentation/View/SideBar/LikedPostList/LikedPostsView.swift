import SwiftUI
import Observation

// MARK: - LikedPostsView

struct LikedPostsView: View {
    @State private var engagementViewModel = EngagementViewModel()
    @Environment(CurrentUserManager.self) private var userManager
    @Environment(AppRouter.self) private var appRouter
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info

    var body: some View {
        ZStack {
            if engagementViewModel.isLoadingLikedPosts, engagementViewModel.likedPosts.isEmpty {
                SkeletonLoadingView()
            } else if let errorMessage = engagementViewModel.errorMessage, engagementViewModel.likedPosts.isEmpty {
                if errorMessage.contains("ネットワーク") || errorMessage.contains("接続") {
                    NetworkErrorView {
                        Task {
                            await engagementViewModel.refreshLikedPosts()
                        }
                    }
                } else {
                    ErrorStateView(error: errorMessage) {
                        Task {
                            await engagementViewModel.refreshLikedPosts()
                        }
                    }
                }
            } else if engagementViewModel.likedPosts.isEmpty {
                LikedPostsEmptyStateView()
            } else {
                PostTimeline(
                    posts: engagementViewModel.likedPosts,
                    loading: engagementViewModel.isLoadingLikedPosts,
                    onRefresh: { Task { await engagementViewModel.refreshLikedPosts() } },
                    onLoadMore: { Task { await engagementViewModel.loadMoreLikedPosts() } },
                    embedInScrollView: true,
                    onToggleLike: { (post: Post) async in
                        await engagementViewModel.toggleLike(for: post)
                    }
                )
                .environment(BulletinBoardViewModel())
            }

            VStack {
                ToastView(
                    message: toastMessage,
                    type: toastType,
                    isShowing: $showToast
                )

                Spacer()
            }
            .zIndex(1)
        }
        .navigationTitle("いいねした投稿")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.lightOrangeColor, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
        .onAppear {
            print("[LikedPostsView] onAppear")
        }
        .task {
            if engagementViewModel.likedPosts.isEmpty {
                print("[LikedPostsView] task start -> loadLikedPosts")
                await engagementViewModel.loadLikedPosts()
            }
        }
        .onChange(of: engagementViewModel.errorMessage) { errorMessage in
            if let error = errorMessage {
                print("[LikedPostsView] errorMessage changed -> \(error)")
                showToastMessage(error, type: .error)
            }
        }
        .onChange(of: engagementViewModel.successMessage) { successMessage in
            if !successMessage.isEmpty, engagementViewModel.showSuccessMessage {
                print("[LikedPostsView] successMessage -> \(successMessage)")
                showToastMessage(successMessage, type: .success)
            }
        }
    }

    private func showToastMessage(_ message: String, type: ToastView.ToastType) {
        toastMessage = message
        toastType = type
        withAnimation {
            showToast = true
        }

    }
}

// MARK: - LikedPostsTimeline

private struct LikedPostsTimeline: View {
    let posts: [Post]
    let loading: Bool
    let onRefresh: () -> Void
    let onLoadMore: () -> Void
    let engagementViewModel: EngagementViewModel
    @Environment(AppRouter.self) private var appRouter

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(posts) { post in
                    LikedPostCell(
                        post: post,
                        engagementViewModel: engagementViewModel,
                        onTap: {
                            appRouter.navigate(to: .postDetail(postId: post.id))
                        },
                        onAppear: {
                            if post.id == posts.last?.id {
                                onLoadMore()
                            }
                        }
                    )
                }

                if loading, !posts.isEmpty {
                    PaginationLoadingView()
                }
            }
        }
        .background(Color.white)
        .refreshable {
            onRefresh()
        }
    }
}

// MARK: - LikedPostCell

private struct LikedPostCell: View {
    let post: Post
    let engagementViewModel: EngagementViewModel
    let onTap: () -> Void
    let onAppear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            LikedPostCardView(
                post: post,
                engagementViewModel: engagementViewModel,
                onPostTap: onTap
            )
            .contentShape(Rectangle())
            .onAppear(perform: onAppear)

            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 1)
        }
    }
}

// MARK: - LikedPostCardView

private struct LikedPostCardView: View {
    let post: Post
    let engagementViewModel: EngagementViewModel
    let onPostTap: (() -> Void)?

    var body: some View {
        TimelinePostCardView(
            post: post,
            onPostTap: onPostTap,
            customOnLike: { post in
                await engagementViewModel.toggleLike(for: post)
            }
        )
    }
}

// MARK: - LikedPostsEmptyStateView

private struct LikedPostsEmptyStateView: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var adaptiveTitleSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 16
        case .medium:
            return 18
        case .large:
            return 20
        case .xLarge:
            return 22
        case .xxLarge:
            return 24
        case .xxxLarge:
            return 26
        default:
            return 18
        }
    }

    private var adaptiveSubtitleSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 12
        case .medium:
            return 14
        case .large:
            return 16
        case .xLarge:
            return 17
        case .xxLarge:
            return 18
        case .xxxLarge:
            return 20
        default:
            return 14
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "6B7280"))

            VStack(spacing: 8) {
                Text("いいねした投稿がありません")
                    .font(.system(size: adaptiveTitleSize, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)

                Text("気に入った投稿にいいねしてみましょう")
                    .font(.system(size: adaptiveSubtitleSize))
                    .foregroundColor(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
            }

//            Button(action: {
//                appRouter.popToRoot()
//            }) {
//                Text("投稿を見に行く")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 24)
//                    .padding(.vertical, 12)
//                    .background(Color.primaryOrange)
//                    .cornerRadius(24)
//            }
//            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.top, 100)
    }
}

#Preview {
    LikedPostsView()
        .environment(CurrentUserManager.shared)
}
