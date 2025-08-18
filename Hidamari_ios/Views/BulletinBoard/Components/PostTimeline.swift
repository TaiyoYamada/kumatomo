import SwiftUI

struct PostTimeline: View {
    let posts: [Post]
    let loading: Bool
    let onRefresh: () -> Void
    let onLoadMore: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(posts) { post in
                    PostItemView(post: post)
                        .onAppear {
                            // Trigger load more when near the end
                            if post.id == posts.last?.id {
                                onLoadMore()
                            }
                        }
                    
                    // Post separator
                    Rectangle()
                        .fill(Color(hex: "E5E7EB"))
                        .frame(height: 1)
                        .accessibilityHidden(true)
                }
                
                // Loading indicator for pagination
                if loading && !posts.isEmpty {
                    PaginationLoadingView()
                }
                
                // Empty state
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
        .accessibilityLabel("投稿タイムライン")
        .accessibilityHint("上にスワイプして更新")
        .accessibilityIdentifier("post_timeline")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("まだ投稿がありません。最初の投稿をしてみませんか？")
        .accessibilityIdentifier("bulletin_empty_state")
    }
}

// PostItemView is defined in FeedView.swift to avoid duplication

// Components are defined in FeedView.swift to avoid duplication

#Preview {
    PostTimeline(
        posts: [],
        loading: false,
        onRefresh: {},
        onLoadMore: {}
    )
}