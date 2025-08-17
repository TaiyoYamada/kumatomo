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
    }
}

struct BulletinEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "6B7280"))
            
            Text("まだ投稿がありません")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "1A1A1A"))
            
            Text("最初の投稿をしてみませんか？")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6B7280"))
        }
        .padding(.horizontal, 32)
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