import SwiftUI

/// A view that displays the user's bookmarked posts using the existing post list components
struct BookmarkedPostsView: View {
    @StateObject private var engagementViewModel = EngagementViewModel()
    @EnvironmentObject private var userManager: CurrentUserManager
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    
    var body: some View {
        NavigationStack {
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
            .task {
                // Load bookmarked posts when view appears
                if engagementViewModel.bookmarkedPosts.isEmpty {
                    await engagementViewModel.loadBookmarkedPosts()
                }
            }
            .onChange(of: engagementViewModel.errorMessage) { errorMessage in
                if let error = errorMessage {
                    showToastMessage(error, type: .error)
                }
            }
            .onChange(of: engagementViewModel.successMessage) { successMessage in
                if !successMessage.isEmpty && engagementViewModel.showSuccessMessage {
                    showToastMessage(successMessage, type: .success)
                }
            }
            .withAppRouter()
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
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var userManager: CurrentUserManager
    
    // Date formatter
    private var formattedDate: String {
        guard let createdAt = post.createdAt else { return "" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)
        
        if timeInterval < 60 {
            return "今"
        } else if timeInterval < 3600 {
            return "\(Int(timeInterval / 60))分前"
        } else if timeInterval < 86400 {
            return "\(Int(timeInterval / 3600))時間前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            formatter.locale = Locale(identifier: "ja_JP")
            return formatter.string(from: createdAt)
        }
    }
    
    // Dynamic type sizes
    private var adaptiveUserNameSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 13
        case .medium:
            return 15
        case .large:
            return 16
        case .xLarge:
            return 17
        case .xxLarge:
            return 18
        case .xxxLarge:
            return 20
        default:
            return 15
        }
    }
    
    private var adaptiveTimestampSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 11
        case .medium:
            return 13
        case .large:
            return 14
        case .xLarge:
            return 15
        case .xxLarge:
            return 16
        case .xxxLarge:
            return 17
        default:
            return 13
        }
    }
    
    private var adaptivePadding: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 12
        case .large:
            return 14
        case .xLarge:
            return 16
        case .xxLarge:
            return 18
        case .xxxLarge:
            return 20
        default:
            return 12
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Profile Icon (Left side)
                Button(action: {
                    // Navigate to user profile
                    if let userId = post.user?.id {
                        AppRouter.shared.navigateToUserProfile(userId: userId)
                    }
                }) {
                    AsyncImage(url: URL(string: post.user?.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("\(post.user?.name ?? "ユーザー")のプロフィール画像")
                .accessibilityIdentifier("bookmarked_post_profile_image_\(post.id)")
                
                // Content Area (Right side)
                VStack(alignment: .leading, spacing: 8) {
                    // User Info Header (Twitter-like: Name, @username · time)
                    HStack(spacing: 6) {
                        Text(post.user?.name ?? "ユーザー")
                            .font(.system(size: adaptiveUserNameSize, weight: .semibold))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)

                        if let username = post.user?.username, !username.isEmpty {
                            Text("@\(username)")
                                .font(.system(size: adaptiveTimestampSize))
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }

                        Text("・")
                            .foregroundColor(.secondary)

                        Text(formattedDate)
                            .font(.system(size: adaptiveTimestampSize))
                            .foregroundColor(.secondary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)

                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(post.user?.name ?? "ユーザー")、@\(post.user?.username ?? "user")、\(formattedDate)")
                    
                    // Post Content with hashtags
                    PostContentView(content: post.content)
                    
                    // Post Media
                    if let images = post.images, !images.isEmpty {
                        PostMediaView(images: images)
                    } else if let imageUrl = post.imageUrl, !imageUrl.isEmpty {
                        PostMediaView(imageUrl: imageUrl)
                    }
                    
                    // Category Tags
                    if let tags = post.tags, !tags.isEmpty {
                        CategoryTagsView(tags: tags)
                    }
                    
                    // Engagement Buttons (Show all buttons including bookmark for bookmarked posts)
                    EngagementButtonsView.detail(
                        post: post,
                        onLike: {
                            Task {
                                await engagementViewModel.toggleLike(for: post)
                            }
                        },
                        onComment: {
                            onPostTap?()
                        },
                        onBookmark: {
                            Task {
                                await engagementViewModel.toggleBookmark(for: post)
                            }
                        }
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, adaptivePadding)
            .contentShape(Rectangle())
        }
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("ブックマークした投稿: \(post.user?.name ?? "ユーザー")、\(formattedDate)、\(post.content)")
        .accessibilityHint("タップして投稿詳細を表示")
        .accessibilityIdentifier("bookmarked_post_item_\(post.id)")
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
            
            // Navigate to home button
            Button(action: {
                // Navigate back to home/timeline
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
