import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = PostViewModel()
    @State private var showingNewPost = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Navigation Header
                TabNavigationHeader(
                    activeTab: viewModel.activeTab,
                    selectedMunicipality: viewModel.selectedMunicipality,
                    onTabChange: viewModel.changeTab,
                    onMunicipalityChange: viewModel.changeMunicipality
                )
                
                // Post Timeline
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.posts) { post in
                            PostItemView(post: post)
                            
                            // Post separator
                            Rectangle()
                                .fill(Color(hex: "E5E7EB"))
                                .frame(height: 1)
                        }
                    }
                }
                .background(Color.white)
            }
            .navigationTitle("掲示板")
            .toolbarTitleDisplayMode(.inline)
//            .sheet(isPresented: $showingNewPost) {
//                PostView()
//            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                        )
                }
            }
            .overlay {
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                            .padding()
                        Spacer().frame(height: 100)
                    }
                }
            }
        }
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.fetchAllPosts()
            }
        }
        .refreshable {
            await viewModel.fetchAllPosts()
        }
    }
}

// Twitter-like Post Item View
struct PostItemView: View {
    let post: Post
    @State private var showingPostDetail = false
    
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
                
                // Content Area (Right side)
                VStack(alignment: .leading, spacing: 8) {
                    // User Info Header
                    HStack(spacing: 8) {
                        Text(post.user?.name ?? "ユーザー")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                        
                        Text(formattedDate)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "6B7280"))
                        
                        Spacer()
                    }
                    
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
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingPostDetail) {
            PostDetailView(post: post)
        }
    }
}

// Post Content with hashtag support
struct PostContentView: View {
    let content: String
    
    var body: some View {
        Text(attributedContent)
            .font(.system(size: 16))
            .lineSpacing(1.5)
            .foregroundColor(Color(hex: "1A1A1A"))
            .fixedSize(horizontal: false, vertical: true)
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

// Post Media View
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
                    }
            }
            .frame(maxHeight: 300)
            .clipped()
            .cornerRadius(12)
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
                    }
            }
            .frame(maxHeight: 300)
            .clipped()
            .cornerRadius(12)
        }
    }
}

// Category Tags View
struct CategoryTagsView: View {
    let tags: [String]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(categoryColor(for: tag))
                    .cornerRadius(16)
            }
            Spacer()
        }
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
    
    var body: some View {
        HStack(spacing: 24) {
            // Reaction buttons (👍/🤤/🌶️)
            HStack(spacing: 16) {
                ReactionButton(emoji: "👍", count: 0, isActive: false) {
                    // Handle reaction
                }
                
                ReactionButton(emoji: "🤤", count: 0, isActive: false) {
                    // Handle reaction
                }
                
                ReactionButton(emoji: "🌶️", count: 0, isActive: false) {
                    // Handle reaction
                }
            }
            
            Spacer()
            
            // Comment button
            Button(action: {
                // Handle comment
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .font(.system(size: 16))
                    Text("0")
                        .font(.system(size: 14))
                }
                .foregroundColor(Color(hex: "6B7280"))
            }
            
            // Bookmark button
            Button(action: {
                isBookmarked.toggle()
            }) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16))
                    .foregroundColor(isBookmarked ? Color(hex: "1DA1F2") : Color(hex: "6B7280"))
            }
        }
        .frame(height: 32)
    }
}

// Reaction Button Component
struct ReactionButton: View {
    let emoji: String
    let count: Int
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 16))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 14))
                        .foregroundColor(isActive ? Color(hex: "1DA1F2") : Color(hex: "6B7280"))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
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