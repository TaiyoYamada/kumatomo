import SwiftUI
import Observation

// MARK: - TimelinePostCardView

struct TimelinePostCardView: View {
    let post: Post
    let onPostTap: (() -> Void)?
    let customOnLike: ((Post) async -> Void)?

    @State private var showingPostDetail = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(CurrentUserManager.self) private var userManager
    @Environment(AppRouter.self) private var appRouter

    @State private var isTogglingLike = false
    @State private var isTogglingBookmark = false

    @Environment(\.openURL) private var openURL

    init(post: Post, onPostTap: (() -> Void)? = nil, customOnLike: ((Post) async -> Void)? = nil) {
        self.post = post
        self.onPostTap = onPostTap
        self.customOnLike = customOnLike
    }

    private var formattedDate: String {
        guard let createdAt = post.createdAt else { return "" }

        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)

        if timeInterval < 60 {
            return "今"
        } else if timeInterval < 3_600 {
            return "\(Int(timeInterval / 60))分前"
        } else if timeInterval < 86_400 {
            return "\(Int(timeInterval / 3_600))時間前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            formatter.locale = Locale(identifier: "ja_JP")
            return formatter.string(from: createdAt)
        }
    }

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
                Button(action: {
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

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            // 名前: 長い場合は...で切り詰め
                            Text(post.user?.name ?? "ユーザー")
                                .font(.system(size: adaptiveUserNameSize, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            // ユーザー名: 長い場合は...で切り詰め
                            if let username = post.user?.username, !username.isEmpty {
                                Text("@\(username)")
                                    .font(.system(size: adaptiveTimestampSize))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }

                            // タイムスタンプ: 必ず表示
                            Text("・")
                                .foregroundColor(.secondary)
                                .layoutPriority(1)

                            Text(formattedDate)
                                .font(.system(size: adaptiveTimestampSize))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .layoutPriority(1)

                            Spacer(minLength: 0)
                        }

                        PostContentView(content: post.content)

                        if let images = post.images, !images.isEmpty {
                            PostMediaView(images: images)
                        } else if let imageUrl = post.imageUrl, !imageUrl.isEmpty {
                            PostMediaView(imageUrl: imageUrl)
                        }

                        if let tags = post.tags, !tags.isEmpty {
                            CategoryTagsView(tags: tags)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onPostTap?()
                    }

                    EngagementButtonsView.timeline(
                        post: post,
                        onLike: { @MainActor in
                            if let handler = customOnLike {
                                await handler(post)
                            } else {
                                print("ℹ️ No custom like handler provided")
                            }
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
        }
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("投稿: \(post.user?.name ?? "ユーザー")、\(formattedDate)、\(post.content)")
        .accessibilityHint("タップして投稿詳細を表示")
        .accessibilityIdentifier("post_item_\(post.id)")

    }

    private func navigateToUserProfile(userId: Int) {
        appRouter.navigate(to: .userProfile(userId: userId))
    }
}

#Preview {
    TimelinePostCardViewPreview()
}

// MARK: - TimelinePostCardViewPreview

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
        .environment(CurrentUserManager.shared)
        .environment(BulletinBoardViewModel())
    }
}

// MARK: - PostContentView

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

// MARK: - PostMediaView

struct PostMediaView: View {
    let images: [PostImage]?
    let imageUrl: String?

    init(images: [PostImage]) {
        self.images = images
        imageUrl = nil
    }

    init(imageUrl: String) {
        images = nil
        self.imageUrl = imageUrl
    }

    var body: some View {
        if let images, !images.isEmpty {
            // 複数画像対応: PostImagesGridViewを使用
            PostImagesGridView(images: images)
        } else if let imageUrl, !imageUrl.isEmpty {
            // 単一のURL文字列の場合
            SingleImageGridItem(imageURL: imageUrl) {}
        }
    }
}

// MARK: - CategoryTagsView

struct CategoryTagsView: View {
    let tags: [String]

    var body: some View {
        Text(tags.map { "#\($0)" }.joined(separator: " "))
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("タグ: \(tags.joined(separator: ", "))")
    }
}
