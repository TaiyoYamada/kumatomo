import SwiftUI

struct EngagementButtonDemo: View {
    @State private var likeCount = 42
    @State private var commentCount = 7
    @State private var bookmarkCount = 15
    @State private var isLiked = false
    @State private var isBookmarked = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Engagement Button Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Individual Buttons")
                        .font(.headline)

                    HStack(spacing: 20) {
                        EngagementButton.like(count: likeCount, isLiked: isLiked) {
                            await toggleLike()
                        }

                        EngagementButton.comment(count: commentCount) {
                            await addComment()
                        }

                        EngagementButton.bookmark(count: bookmarkCount, isBookmarked: isBookmarked) {
                            await toggleBookmark()
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Number Formatting Examples")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Small numbers: \(5.formatCount()), \(127.formatCount()), \(999.formatCount())")
                        Text("Thousands: \(1234.formatCount()), \(15678.formatCount())")
                        Text("Millions: \(1234567.formatCount()), \(42000000.formatCount())")
                        Text("Billions: \(1234567890.formatCount())")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Post with Engagement Buttons")
                        .font(.headline)

                    let samplePost = createSamplePost()

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)

                                VStack(alignment: .leading) {
                                    Text("Sample User")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("2時間前")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }

                            Text("This is a sample post to demonstrate the engagement buttons. You can like, comment, and bookmark this post!")
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        EngagementButtonsView.detail(
                            post: samplePost,
                            onLike: { await toggleLike() },
                            onComment: { await addComment() },
                            onBookmark: { await toggleBookmark() }
                        )

                        EngagementSummaryView(post: samplePost)

                        EngagementStatsView(post: samplePost)
                    }
                }

                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("Engagement Demo")
        .navigationBarTitleDisplayMode(.inline)
    }


    private func createSamplePost() -> Post {
        var post = Post(id: 1, userId: 1, content: "Sample post content")
        post.likeCount = likeCount
        post.commentCount = commentCount
        post.bookmarkCount = bookmarkCount
        post.isLikedByCurrentUser = isLiked
        post.isBookmarkedByCurrentUser = isBookmarked
        return post
    }

    private func toggleLike() async {
        try? await Task.sleep(nanoseconds: 100_000_000)

        await MainActor.run {
            if isLiked {
                likeCount = max(0, likeCount - 1)
                isLiked = false
            } else {
                likeCount += 1
                isLiked = true
            }
        }
    }

    private func toggleBookmark() async {
        try? await Task.sleep(nanoseconds: 100_000_000)

        await MainActor.run {
            if isBookmarked {
                bookmarkCount = max(0, bookmarkCount - 1)
                isBookmarked = false
            } else {
                bookmarkCount += 1
                isBookmarked = true
            }
        }
    }

    private func addComment() async {
        try? await Task.sleep(nanoseconds: 200_000_000)

        await MainActor.run {
            commentCount += 1
        }
    }
}
