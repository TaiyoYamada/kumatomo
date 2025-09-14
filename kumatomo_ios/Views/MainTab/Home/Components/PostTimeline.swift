import SwiftUI

struct PostTimeline: View {
    let posts: [Post]
    let loading: Bool
    let onRefresh: () -> Void
    let onLoadMore: () -> Void
    
    @EnvironmentObject private var bulletinBoardViewModel: BulletinBoardViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(posts) { post in
                    PostCell(
                        post: post,
                        onTap: {
                            AppRouter.shared.navigateToPostDetail(postId: post.id)
                        },
                        onAppear: {
                            // 最後の投稿が表示されたら、新しい投稿を読み込みます
                            if post.id == posts.last?.id {
                                onLoadMore()
                            }
                        }
                    )
                }

                // 次のページを読み込んでいる時のインジケーター
                if loading && !posts.isEmpty {
                    // PaginationLoadingViewはアプリの他の場所で定義されていると仮定します
                    PaginationLoadingView()
                }

                // 投稿がまだない時の表示
                if posts.isEmpty && !loading {
                    BulletinEmptyStateView()
                        .padding(.top, 100)
                }
            }
        }
        .background(Color.white)
        .refreshable {
            onRefresh()
        }
    }
}

private struct PostCell: View {
    let post: Post
    let onTap: () -> Void
    let onAppear: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            TimelinePostCardView(post: post)
                .onTapGesture {
                    print("こんにちはタップしたよ")
                    onTap()
                }
                .contentShape(Rectangle())
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




