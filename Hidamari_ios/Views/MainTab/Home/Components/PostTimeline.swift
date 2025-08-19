import SwiftUI

struct PostTimeline: View {
    let posts: [Post]
    let loading: Bool
    let onRefresh: () -> Void
    let onLoadMore: () -> Void
    @State private var selectedPost: Post?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(posts) { post in
                    ModernPostCardView(post: post)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPost = post
                        }
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
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("まだ投稿がありません。最初の投稿をしてみませんか？")
        .accessibilityIdentifier("bulletin_empty_state")
    }
}

// Twitter-like Post Item View
struct PostItemView: View {
    let post: Post
    @State private var showingPostDetail = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    // 日付フォーマッター
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
        Button(action: { showingPostDetail = true }) {
            HStack(alignment: .top, spacing: 12) {
                // Profile Icon (Left side)
                AsyncImage(url: URL(string: post.user?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(Color(hex: "6B7280"))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .accessibilityLabel("\(post.user?.name ?? "ユーザー")のプロフィール画像")
                .accessibilityIdentifier("post_profile_image_\(post.id)")
                
                // Content Area (Right side)
                VStack(alignment: .leading, spacing: 8) {
                    // User Info Header
                    HStack(spacing: 8) {
                        Text(post.user?.name ?? "ユーザー")
                            .font(.system(size: adaptiveUserNameSize, weight: .semibold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                        
                        Text(formattedDate)
                            .font(.system(size: adaptiveTimestampSize))
                            .foregroundColor(Color(hex: "6B7280"))
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(post.user?.name ?? "ユーザー")、\(formattedDate)")
                    
                    // Post Content with hashtags
                    PostContentView(content: post.content)
                    
                    // Post Media
                    if let images = post.images, !images.isEmpty {
                        PostMediaView(images: images)
                    } else if let imageUrl = post.imageUrl {
                        PostMediaView(imageUrl: imageUrl)
                    }
                    
                    // Category Tags
                    if let tags = post.tags, !tags.isEmpty {
                        CategoryTagsView(tags: tags)
                    }
                    
                    // Action Bar
                    PostActionBar(post: post)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, adaptivePadding)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("投稿: \(post.user?.name ?? "ユーザー")、\(formattedDate)、\(post.content)")
        .accessibilityHint("タップして投稿詳細を表示")
        .accessibilityIdentifier("post_item_\(post.id)")
        .sheet(isPresented: $showingPostDetail) {
            PostDetailView(post: post)
        }
    }
}

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
            .foregroundColor(Color(hex: "1A1A1A"))
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
                        attributedString[attributedRange].foregroundColor = Color(hex: "1DA1F2")
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
        } else if let imageUrl = imageUrl {
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

// Category Tags View
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
            return Color(hex: "10B981")
        case "イベント":
            return Color(hex: "F59E0B")
        case "緊急":
            return Color(hex: "EF4444")
        default:
            return Color(hex: "8B5CF6")
        }
    }
}

// Post Action Bar
struct PostActionBar: View {
    let post: Post
    @State private var isReacted = false
    @State private var isBookmarked = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var adaptiveIconSize: CGFloat {
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
    
    private var adaptiveTextSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 12
        case .medium:
            return 14
        case .large:
            return 15
        case .xLarge:
            return 16
        case .xxLarge:
            return 17
        case .xxxLarge:
            return 18
        default:
            return 14
        }
    }
    
    private var adaptiveBarHeight: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 44 // Minimum touch target
        case .large:
            return 46
        case .xLarge:
            return 48
        case .xxLarge:
            return 50
        case .xxxLarge:
            return 52
        default:
            return 44
        }
    }
    
    var body: some View {
        HStack(spacing: 24) {
            // Reaction buttons (👍/🤤/🌶️)
            HStack(spacing: 16) {
                ReactionButton(emoji: "👍", count: 0, isActive: false) {
                    // Handle reaction
                }
                
//                ReactionButton(emoji: "🤤", count: 0, isActive: false) {
//                    // Handle reaction
//                }
//                
//                ReactionButton(emoji: "🌶️", count: 0, isActive: false) {
//                    // Handle reaction
//                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("リアクションボタン")
            
            Spacer()
            
            // Comment button
            Button(action: {
                // Handle comment
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .font(.system(size: adaptiveIconSize))
                    Text("0")
                        .font(.system(size: adaptiveTextSize))
                }
                .foregroundColor(Color(hex: "6B7280"))
            }
            .frame(minWidth: 44, minHeight: 44) // Ensure minimum touch target
            .accessibilityLabel("コメント")
            .accessibilityHint("タップしてコメントを表示")
            .accessibilityIdentifier("comment_button")
            
            // Bookmark button
            Button(action: {
                isBookmarked.toggle()
            }) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: adaptiveIconSize))
                    .foregroundColor(isBookmarked ? Color(hex: "1DA1F2") : Color(hex: "6B7280"))
            }
            .frame(minWidth: 44, minHeight: 44) // Ensure minimum touch target
            .accessibilityLabel(isBookmarked ? "ブックマーク済み" : "ブックマーク")
            .accessibilityHint(isBookmarked ? "タップしてブックマークを解除" : "タップしてブックマークに追加")
            .accessibilityIdentifier("bookmark_button")
        }
        .frame(minHeight: adaptiveBarHeight)
        .accessibilityElement(children: .contain)
    }
}

// Reaction Button Component
struct ReactionButton: View {
    let emoji: String
    let count: Int
    let isActive: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var adaptiveEmojiSize: CGFloat {
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
    
    private var adaptiveCountSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 12
        case .medium:
            return 14
        case .large:
            return 15
        case .xLarge:
            return 16
        case .xxLarge:
            return 17
        case .xxxLarge:
            return 18
        default:
            return 14
        }
    }
    
    private var reactionName: String {
        switch emoji {
        case "👍":
            return "いいね"
//        case "🤤":
//            return "おいしそう"
//        case "🌶️":
//            return "辛そう"
        default:
            return "リアクション"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: adaptiveEmojiSize))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: adaptiveCountSize))
                        .foregroundColor(isActive ? Color(hex: "1DA1F2") : Color(hex: "6B7280"))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minWidth: 44, minHeight: 44) // Ensure minimum touch target
        .accessibilityLabel("\(reactionName)\(count > 0 ? "、\(count)件" : "")")
        .accessibilityHint(isActive ? "タップして\(reactionName)を取り消し" : "タップして\(reactionName)を追加")
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityIdentifier("reaction_button_\(emoji)")
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
