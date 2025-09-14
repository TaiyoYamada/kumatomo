import SwiftUI

/// A modern Twitter-like post card view for displaying posts in the timeline
struct TimelinePostCardView: View {
    let post: Post
    let onPostTap: (() -> Void)?
    
    @State private var showingPostDetail = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var userManager: CurrentUserManager
    @EnvironmentObject private var bulletinBoardViewModel: BulletinBoardViewModel
    
    // Engagement state
    @State private var isTogglingLike = false
    @State private var isTogglingBookmark = false
    
    // Navigation
    @Environment(\.openURL) private var openURL
    
    // MARK: - Initializers
    
    init(post: Post, onPostTap: (() -> Void)? = nil) {
        self.post = post
        self.onPostTap = onPostTap
    }
    
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
                        navigateToUserProfile(userId: userId)
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
                
                // Content Area (Right side)
                VStack(alignment: .leading, spacing: 8) {
                    // User Info Header (Twitter-like: Name, @username · time)
                    HStack(spacing: 6) {
                        Text(post.user?.name ?? "ユーザー")
                            .font(.system(size: adaptiveUserNameSize, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if let username = post.user?.username, !username.isEmpty {
                            Text("@\(username)")
                                .font(.system(size: adaptiveTimestampSize))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Text("・")
                            .foregroundColor(.secondary)

                        Text(formattedDate)
                            .font(.system(size: adaptiveTimestampSize))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer()
                    }
                    
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
                    
                    // Engagement Buttons (Timeline version - no bookmark count)
                    EngagementButtonsView.timeline(
                        post: post,
                        onLike: {
                            bulletinBoardViewModel.toggleLike(for: post)
                        },
                        onComment: {
                            onPostTap?()
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
        .accessibilityLabel("投稿: \(post.user?.name ?? "ユーザー")、\(formattedDate)、\(post.content)")
        .accessibilityHint("タップして投稿詳細を表示")
        .accessibilityIdentifier("post_item_\(post.id)")

    }
    

    
    /// Navigate to user profile
    private func navigateToUserProfile(userId: Int) {
        AppRouter.shared.navigateToUserProfile(userId: userId)
    }
}



// MARK: - Preview

#Preview {
    TimelinePostCardViewPreview()
}

struct TimelinePostCardViewPreview: View {
    var body: some View {
        let samplePost = Post(
            id: 1,
            userId: 1,
            content: "これはサンプル投稿です。#テスト #SwiftUI"
        )
        
        var engagedPost = samplePost
        engagedPost.likeCount = 42
        engagedPost.commentCount = 7
        engagedPost.isLikedByCurrentUser = true
        engagedPost.user = User(
            id: 1,
            email: "test@example.com",
            name: "テストユーザー",
            username: nil,
            profileImageURL: nil,
            coverImageURL: nil,
            bio: nil,
            location: nil,
            birthday: nil,
            postCount: nil,
            followingCount: nil,
            followersCount: nil,
            hasCompletedSetup: nil,
            createdAt: nil,
            isVerified: nil,
            joinedDate: nil
        )
        engagedPost.tags = ["グルメ", "イベント"]
        
        return VStack(spacing: 0) {
            TimelinePostCardView(post: engagedPost)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            TimelinePostCardView(post: samplePost)
        }
        .environmentObject(CurrentUserManager.shared)
        .environmentObject(BulletinBoardViewModel())
    }
}

// MARK: - Supporting Views

struct PostContentView: View {
    let content: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var adaptiveContentSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 17
        case .xLarge:
            return 18
        case .xxLarge:
            return 20
        case .xxxLarge:
            return 22
        default:
            return 16
        }
    }
    
    var body: some View {
        Text(attributedContent)
            .font(.system(size: adaptiveContentSize))
            .lineSpacing(1.5)
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(content)
            .accessibilityIdentifier("post_content")
    }
    
    private var attributedContent: AttributedString {
        var attributedString = AttributedString(content)
        
        // Find hashtags and make them blue
        let hashtagPattern = #"#\w+"#
        if let regex = try? NSRegularExpression(pattern: hashtagPattern) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: content) {
                    if let attributedRange = Range(match.range, in: attributedString) {
                        attributedString[attributedRange].foregroundColor = .blue
                    }
                }
            }
        }
        
        return attributedString
    }
}

struct PostMediaView: View {
    let images: [PostImage]?
    let imageUrl: String?
    
    init(images: [PostImage]) {
        self.images = images
        self.imageUrl = nil
    }
    
    init(imageUrl: String) {
        self.images = nil
        self.imageUrl = imageUrl
    }
    
    var body: some View {
        if let images = images, !images.isEmpty {
            AsyncImage(url: URL(string: images.first!.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                            .accessibilityLabel("画像を読み込み中")
                    }
            }
            .frame(maxHeight: 300)
            .clipped()
            .cornerRadius(12)
            .accessibilityLabel("投稿画像")
            .accessibilityHint("投稿に添付された画像")
            .accessibilityIdentifier("post_image")
        } else if let imageUrl = imageUrl, !imageUrl.isEmpty {
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                            .accessibilityLabel("画像を読み込み中")
                    }
            }
            .frame(maxHeight: 300)
            .clipped()
            .cornerRadius(12)
            .accessibilityLabel("投稿画像")
            .accessibilityHint("投稿に添付された画像")
            .accessibilityIdentifier("post_image")
        }
    }
}

struct CategoryTagsView: View {
    let tags: [String]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var adaptiveTagSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 10
        case .medium:
            return 12
        case .large:
            return 13
        case .xLarge:
            return 14
        case .xxLarge:
            return 15
        case .xxxLarge:
            return 16
        default:
            return 12
        }
    }
    
    private var adaptivePadding: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 3
        case .medium:
            return 4
        case .large:
            return 5
        case .xLarge:
            return 6
        case .xxLarge:
            return 7
        case .xxxLarge:
            return 8
        default:
            return 4
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: adaptiveTagSize, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, adaptivePadding)
                    .background(categoryColor(for: tag))
                    .cornerRadius(16)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .accessibilityLabel("カテゴリー: \(tag)")
                    .accessibilityIdentifier("category_tag_\(tag)")
            }
            Spacer()
        }
        .accessibilityElement(children: .contain)
    }
    
    private func categoryColor(for tag: String) -> Color {
        switch tag {
        case "グルメ":
            return .green
        case "イベント":
            return .orange
        case "緊急":
            return .red
        default:
            return .purple
        }
    }
}
