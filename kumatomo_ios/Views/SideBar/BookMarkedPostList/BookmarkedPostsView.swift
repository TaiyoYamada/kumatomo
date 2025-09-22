import SwiftUI

/// A view that displays the user's bookmarked posts using the existing post list components
struct BookmarkedPostsView: View {
    @StateObject private var engagementViewModel = EngagementViewModel()
    @EnvironmentObject private var userManager: CurrentUserManager
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    
    var body: some View {
        ZStack {
            // Main content
            if engagementViewModel.isLoadingBookmarkedPosts && engagementViewModel.bookmarkedPosts.isEmpty {
                // Loading state for initial load
                SkeletonLoadingView()
            } else if let errorMessage = engagementViewModel.errorMessage, engagementViewModel.bookmarkedPosts.isEmpty {
                // Error state when no posts are loaded
                if errorMessage.contains("ネットワーク") || errorMessage.contains("接続") {
                    NetworkErrorView {
                        Task {
                            await engagementViewModel.refreshBookmarkedPosts()
                        }
                    }
                } else {
                    ErrorStateView(error: errorMessage) {
                        Task {
                            await engagementViewModel.refreshBookmarkedPosts()
                        }
                    }
                }
            } else if engagementViewModel.bookmarkedPosts.isEmpty {
                // Empty state
                BookmarkedPostsEmptyStateView()
            } else {
                // Posts list
                BookmarkedPostsTimeline(
                    posts: engagementViewModel.bookmarkedPosts,
                    loading: engagementViewModel.isLoadingBookmarkedPosts,
                    onRefresh: {
                        Task {
                            await engagementViewModel.refreshBookmarkedPosts()
                        }
                    },
                    onLoadMore: {
                        Task {
                            await engagementViewModel.loadMoreBookmarkedPosts()
                        }
                    },
                    engagementViewModel: engagementViewModel
                )
            }
            
            // Toast notification
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
        .navigationTitle("ブックマークした投稿")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("[BookmarkedPostsView] onAppear")
        }
        .task {
            // Load bookmarked posts when view appears
            if engagementViewModel.bookmarkedPosts.isEmpty {
                print("[BookmarkedPostsView] task start -> loadBookmarkedPosts")
                await engagementViewModel.loadBookmarkedPosts()
            }
        }
        .onChange(of: engagementViewModel.errorMessage) { errorMessage in
            if let error = errorMessage {
                print("[BookmarkedPostsView] errorMessage changed -> \(error)")
                showToastMessage(error, type: .error)
            }
        }
        .onChange(of: engagementViewModel.successMessage) { successMessage in
            if !successMessage.isEmpty && engagementViewModel.showSuccessMessage {
                print("[BookmarkedPostsView] successMessage -> \(successMessage)")
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

// MARK: - Bookmarked Posts Timeline

private struct BookmarkedPostsTimeline: View {
    let posts: [Post]
    let loading: Bool
    let onRefresh: () -> Void
    let onLoadMore: () -> Void
    let engagementViewModel: EngagementViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(posts) { post in
                    BookmarkedPostCell(
                        post: post,
                        engagementViewModel: engagementViewModel,
                        onTap: { 
                            // Navigate to post detail using AppRouter
                            AppRouter.shared.navigateToPostDetail(postId: post.id)
                        },
                        onAppear: {
                            // Load more when reaching the last post
                            if post.id == posts.last?.id {
                                onLoadMore()
                            }
                        }
                    )
                }

                // Loading indicator for pagination
                if loading && !posts.isEmpty {
                    PaginationLoadingView()
                }
            }
        }
        .background(Color.white)
        .refreshable {
            onRefresh()
        }
        .accessibilityLabel("ブックマークした投稿一覧")
        .accessibilityHint("上にスワイプして更新")
        .accessibilityIdentifier("bookmarked_posts_timeline")
    }
}

// MARK: - Bookmarked Post Cell

private struct BookmarkedPostCell: View {
    let post: Post
    let engagementViewModel: EngagementViewModel
    let onTap: () -> Void
    let onAppear: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            BookmarkedPostCardView(
                post: post,
                engagementViewModel: engagementViewModel,
                onPostTap: onTap
            )
            .contentShape(Rectangle())
            .onAppear(perform: onAppear)

            // Divider between posts
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 1)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Bookmarked Post Card View

private struct BookmarkedPostCardView: View {
    let post: Post
    let engagementViewModel: EngagementViewModel
    let onPostTap: (() -> Void)?

    var body: some View {
        // Reuse the exact same timeline post card as the main list
        TimelinePostCardView(
            post: post,
            onPostTap: onPostTap,
            customOnLike: { post in
                await engagementViewModel.toggleLike(for: post)
            }
        )
    }
}

// MARK: - Empty State View

private struct BookmarkedPostsEmptyStateView: View {
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
            Image(systemName: "bookmark")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "6B7280"))
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text("ブックマークした投稿がありません")
                    .font(.system(size: adaptiveTitleSize, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)
                
                Text("後で読みたい投稿をブックマークしてみましょう")
                    .font(.system(size: adaptiveSubtitleSize))
                    .foregroundColor(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
            }
            
            // Navigate to bulletin board button
            Button(action: {
                // Navigate back to timeline
                AppRouter.shared.popToRoot()
            }) {
                Text("投稿を見に行く")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primaryOrange)
                    .cornerRadius(24)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.top, 100)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ブックマークした投稿がありません。後で読みたい投稿をブックマークしてみましょう。投稿を見に行くボタン")
        .accessibilityIdentifier("bookmarked_posts_empty_state")
    }
}

// MARK: - Preview

#Preview {
    BookmarkedPostsView()
        .environmentObject(CurrentUserManager.shared)
}
