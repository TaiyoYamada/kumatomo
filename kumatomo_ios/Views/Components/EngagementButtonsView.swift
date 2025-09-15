import SwiftUI

/// A view that displays engagement buttons (like, comment, bookmark) for a post
struct EngagementButtonsView: View {
    let post: Post
    let showBookmark: Bool
    let onLike: () async -> Void
    let onComment: () async -> Void
    let onBookmark: () async -> Void
    
    // Animation state
    @State private var isAnimating = false
    
    init(
        post: Post,
        showBookmark: Bool = true,
        onLike: @escaping () async -> Void,
        onComment: @escaping () async -> Void,
        onBookmark: @escaping () async -> Void = {}
    ) {
        self.post = post
        self.showBookmark = showBookmark
        self.onLike = onLike
        self.onComment = onComment
        self.onBookmark = onBookmark
    }
    
    var body: some View {
        HStack(spacing: 24) {
            // Like button
            EngagementButton.like(
                count: post.likeCount ?? 0,
                isLiked: post.isLikedByCurrentUser ?? false,
                action: onLike
            )
            
            // Comment button
            EngagementButton.comment(
                count: post.commentCount ?? 0,
                action: onComment
            )
            
            // Bookmark button (conditionally shown)
            if showBookmark {
                EngagementButton.bookmark(
                    count: post.bookmarkCount ?? 0,
                    isBookmarked: post.isBookmarkedByCurrentUser ?? false,
                    action: onBookmark
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Convenience Initializers

extension EngagementButtonsView {
    /// Creates engagement buttons for timeline view (no bookmark count shown)
    static func timeline(
        post: Post,
        onLike: @escaping () async -> Void,
        onComment: @escaping () async -> Void
    ) -> EngagementButtonsView {
        EngagementButtonsView(
            post: post,
            showBookmark: false,
            onLike: onLike,
            onComment: onComment,
            onBookmark: {}
        )
    }
    
    /// Creates engagement buttons for post detail view (all buttons shown)
    static func detail(
        post: Post,
        onLike: @escaping () async -> Void,
        onComment: @escaping () async -> Void,
        onBookmark: @escaping () async -> Void
    ) -> EngagementButtonsView {
        EngagementButtonsView(
            post: post,
            showBookmark: true,
            onLike: onLike,
            onComment: onComment,
            onBookmark: onBookmark
        )
    }
}

// MARK: - Engagement Summary View

/// A compact view showing engagement summary text
struct EngagementSummaryView: View {
    let post: Post
    
    var body: some View {
        if !post.engagementSummary.isEmpty {
            Text(post.engagementSummary)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - Engagement Stats View

/// A detailed view showing individual engagement statistics
struct EngagementStatsView: View {
    let post: Post
    let onLikedByTap: (() -> Void)?
    let onBookmarkedByTap: (() -> Void)?
    
    init(
        post: Post,
        onLikedByTap: (() -> Void)? = nil,
        onBookmarkedByTap: (() -> Void)? = nil
    ) {
        self.post = post
        self.onLikedByTap = onLikedByTap
        self.onBookmarkedByTap = onBookmarkedByTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Like count
            if let likeCount = post.likeCount, likeCount > 0 {
                Button {
                    onLikedByTap?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Text("\(likeCount.formatCount())人がいいねしました")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(onLikedByTap == nil)
            }
            
            // Bookmark count
            if let bookmarkCount = post.bookmarkCount, bookmarkCount > 0 {
                Button {
                    onBookmarkedByTap?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.primaryOrange)
                            .font(.caption)
                        
                        Text("\(bookmarkCount.formatCount())人がブックマークしました")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(onBookmarkedByTap == nil)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    // Create sample post data outside the ViewBuilder
    let samplePost = Post(
        id: 1,
        userId: 1,
        content: "Sample post content"
    )
    
    // Create engaged post with engagement data
    var engagedPost = samplePost
    engagedPost.likeCount = 42
    engagedPost.commentCount = 7
    engagedPost.bookmarkCount = 15
    engagedPost.isLikedByCurrentUser = true
    engagedPost.isBookmarkedByCurrentUser = false
    
    return VStack(spacing: 20) {
        
        // Timeline view (no bookmark)
        VStack(alignment: .leading) {
            Text("Timeline View")
                .font(.headline)
            
            EngagementButtonsView.timeline(
                post: engagedPost,
                onLike: { print("Like tapped") },
                onComment: { print("Comment tapped") }
            )
        }
        
        Divider()
        
        // Detail view (with bookmark)
        VStack(alignment: .leading) {
            Text("Detail View")
                .font(.headline)
            
            EngagementButtonsView.detail(
                post: engagedPost,
                onLike: { print("Like tapped") },
                onComment: { print("Comment tapped") },
                onBookmark: { print("Bookmark tapped") }
            )
        }
        
        Divider()
        
        // Engagement summary
        VStack(alignment: .leading) {
            Text("Engagement Summary")
                .font(.headline)
            
            EngagementSummaryView(post: engagedPost)
        }
        
        Divider()
        
        // Engagement stats
        VStack(alignment: .leading) {
            Text("Engagement Stats")
                .font(.headline)
            
            EngagementStatsView(
                post: engagedPost,
                onLikedByTap: { print("Liked by tapped") },
                onBookmarkedByTap: { print("Bookmarked by tapped") }
            )
        }
        
        Spacer()
    }
    .padding()
}