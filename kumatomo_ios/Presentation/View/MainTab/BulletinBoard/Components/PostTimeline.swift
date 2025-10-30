import SwiftUI
import Observation

struct PostTimeline: View {
    let posts: [Post]
    let loading: Bool
    let onRefresh: () -> Void
    let onLoadMore: () -> Void
    var embedInScrollView: Bool = true
    // Optional like toggle handler for callers that own their own posts array
    var onToggleLike: ((Post) async -> Void)? = nil
    
    @Environment(BulletinBoardViewModel.self) private var bulletinBoardViewModel
    @Environment(AppRouter.self) private var appRouter

    @ViewBuilder
    private var timelineContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(posts) { post in
                PostCell(
                    post: post,
                    onTap: {
                        appRouter.navigateToPostDetail(postId: post.id)
                    },
                    onAppear: {
                        // 最後の投稿が表示されたら、新しい投稿を読み込みます
                        if post.id == posts.last?.id {
                            onLoadMore()
                        }
                    },
                    onToggleLike: { post in
                        if let handler = onToggleLike {
                            await handler(post)
                        } else {
                            // Default to bulletin board VM when no handler provided
                            bulletinBoardViewModel.toggleLike(for: post)
                        }
                    }
                )
            }

            // 次のページを読み込んでいる時のインジケーター
            if loading && !posts.isEmpty {
                PaginationLoadingView()
            }

            // 投稿がまだない時の表示
            if posts.isEmpty && !loading {
                BulletinEmptyStateView()
                    .padding(.top, 100)
            }
        }
    }

    var body: some View {
        Group {
            if embedInScrollView {
                ScrollView {
                    timelineContent
                }
                .refreshable { onRefresh() }
            } else {
                timelineContent
            }
        }
        .background(Color.white)
    }
}

private struct PostCell: View {
    let post: Post
    let onTap: () -> Void
    let onAppear: () -> Void
    let onToggleLike: (Post) async -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Pass tap handler into the card so it can
            // attach the gesture only to non-button areas.
            TimelinePostCardView(
                post: post,
                onPostTap: onTap,
                customOnLike: onToggleLike
            )
                .onAppear(perform: onAppear)

            // 投稿ごとの区切り線
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 1)
                .accessibilityHidden(true)
        }
    }
}

struct BulletinEmptyStateView: View {
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
        VStack(spacing: 16) {
            Image(systemName: "message.circle")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "6B7280"))
                .accessibilityHidden(true)
            
            Text("まだ投稿がありません")
                .font(.system(size: adaptiveTitleSize, weight: .medium))
                .foregroundColor(Color(hex: "1A1A1A"))
                .multilineTextAlignment(.center)
            
            Text("最初の投稿をしてみませんか？")
                .font(.system(size: adaptiveSubtitleSize))
                .foregroundColor(Color(hex: "6B7280"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}
