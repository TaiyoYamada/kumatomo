import SwiftUI

// MARK: - PostContentSection

struct PostContentSection: View {
    let post: Post
    let onProfileTap: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var formattedDateLine: String {
        guard let createdAt = post.createdAt else { return "" }
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ja_JP")
        timeFormatter.dateFormat = "H:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy/MM/dd"
        return "\(timeFormatter.string(from: createdAt)) ・ \(dateFormatter.string(from: createdAt))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onProfileTap) {
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
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.user?.name ?? "ユーザー")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        if post.user?.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                        }
                    }
                    Text("@\(post.user?.username ?? "user")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Text(post.content)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let images = post.images, !images.isEmpty {
                PostImagesGridView(images: images)
            } else if let imageUrl = post.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(maxHeight: 400)
                .cornerRadius(12)
            }

            if !formattedDateLine.isEmpty {
                Text(formattedDateLine)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - EngagementSection

struct EngagementSection: View {
    let post: Post
    let isTogglingLike: Bool
    let isTogglingBookmark: Bool
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onComment: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if (post.likeCount ?? 0) > 0 || (post.bookmarkCount ?? 0) > 0 {
                HStack(spacing: 16) {
                    if let likeCount = post.likeCount, likeCount > 0 {
                        HStack(spacing: 4) {
                            Text("\(likeCount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("いいね")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    if let bookmarkCount = post.bookmarkCount, bookmarkCount > 0 {
                        HStack(spacing: 4) {
                            Text("\(bookmarkCount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("ブックマーク")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            EngagementButtonsView.detail(
                post: post,
                onLike: {
                    if !isTogglingLike { onLike() }
                },
                onComment: onComment,
                onBookmark: {
                    if !isTogglingBookmark { onBookmark() }
                }
            )
        }
    }
}

// MARK: - CommentsSection

struct CommentsSection: View {

    let comments: [Comment]
    let isLoading: Bool
    let onRefresh: () -> Void
    let onUserTap: ((Int) -> Void)?
    let onImageTap: ((String) -> Void)?

    @State private var expandedComments: Set<Int> = []

    private let maxContentLines: Int = 3

    init(
        comments: [Comment],
        isLoading: Bool,
        onRefresh: @escaping () -> Void,
        onUserTap: ((Int) -> Void)? = nil,
        onImageTap: ((String) -> Void)? = nil
    ) {
        self.comments = comments
        self.isLoading = isLoading
        self.onRefresh = onRefresh
        self.onUserTap = onUserTap
        self.onImageTap = onImageTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            if isLoading, comments.isEmpty {
                loadingView
            } else if comments.isEmpty {
                emptyStateView
            } else {
                commentsListView
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("コメントセクション、\(comments.count)件のコメント")
    }

    private var sectionHeader: some View {
        HStack {
            Text("コメント")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            if !comments.isEmpty {
                Text("(\(comments.count))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isLoading, !comments.isEmpty {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0 ..< 3, id: \.self) { _ in
                commentSkeletonView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityLabel("コメントを読み込み中")
    }

    private var commentSkeletonView: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 36, height: 36)
                .shimmer()

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 14)
                    .shimmer()

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 14)
                        .shimmer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 200, height: 14)
                        .shimmer()
                }
            }

            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {}
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)

    }

    private var commentsListView: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(comments) { comment in
                EnhancedCommentItemView(
                    comment: comment,
                    isExpanded: expandedComments.contains(comment.id),
                    maxContentLines: maxContentLines,
                    onUserTap: onUserTap,
                    onImageTap: onImageTap,
                    onExpandToggle: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedComments.contains(comment.id) {
                                expandedComments.remove(comment.id)
                            } else {
                                expandedComments.insert(comment.id)
                            }
                        }
                    }
                )
                .id(comment.id)

                if comment.id != comments.last?.id {
                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
    }
}

// MARK: - CommentItemView

struct CommentItemView: View {
    let comment: Comment

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: comment.createdAt, relativeTo: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: comment.user?.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(comment.user?.name ?? "ユーザー")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                if !comment.content.isEmpty {
                    Text(comment.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let imageUrl = comment.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay {
                                ProgressView()
                            }
                    }
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - EnhancedCommentItemView

struct EnhancedCommentItemView: View {

    let comment: Comment
    let isExpanded: Bool
    let maxContentLines: Int
    let onUserTap: ((Int) -> Void)?
    let onImageTap: ((String) -> Void)?
    let onExpandToggle: () -> Void

    private let profileImageSize: CGFloat = 36
    private let imageMaxHeight: CGFloat = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                profileImageView

                VStack(alignment: .leading, spacing: 8) {
                    userInfoView

                    if comment.hasContent {
                        commentContentView
                    }

                    if comment.hasImage {
                        commentImageView
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(commentAccessibilityLabel)
    }

    private var profileImageView: some View {
        Button {
            if let userId = comment.user?.id {
                onUserTap?(userId)
            }
        } label: {
            PostUserImageView(
                imageURL: comment.user?.profileImageURL,
                size: profileImageSize
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("ユーザープロフィール: \(comment.user?.name ?? "不明なユーザー")")
        .accessibilityHint("タップしてプロフィールを表示")
    }

    private var userInfoView: some View {
        HStack(spacing: 8) {
            Button {
                if let userId = comment.user?.id {
                    onUserTap?(userId)
                }
            } label: {
                Text(comment.user?.name ?? "不明なユーザー")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .buttonStyle(PlainButtonStyle())

            if let username = comment.user?.username {
                Text("@\(username)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Text("・")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Text(comment.relativeTimeString)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(comment.user?.name ?? "不明なユーザー")、\(comment.relativeTimeString)")
    }

    private var commentContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            let shouldShowExpandButton = comment.content.components(separatedBy: .newlines).count > maxContentLines

            Text(comment.content)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineLimit(isExpanded ? nil : maxContentLines)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("コメント内容: \(comment.content)")

            if shouldShowExpandButton {
                Button {
                    onExpandToggle()
                } label: {
                    Text(isExpanded ? "折りたたむ" : "もっと見る")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryOrange)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(isExpanded ? "コメントを折りたたむ" : "コメントをすべて表示")
            }
        }
    }

    private var commentImageView: some View {
        Group {
            if let imageUrl = comment.imageUrl, !imageUrl.isEmpty {
                Button {
                    onImageTap?(imageUrl)
                } label: {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .frame(height: 120)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                                )
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: imageMaxHeight)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                                )
                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .frame(height: 120)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 24))
                                            .foregroundColor(.secondary)
                                        Text("画像を読み込めませんでした")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("コメント画像")
                .accessibilityHint("タップして拡大表示")
            }
        }
    }

    private var commentAccessibilityLabel: String {
        var label = "\(comment.user?.name ?? "不明なユーザー")のコメント、\(comment.relativeTimeString)"

        if comment.hasContent {
            label += "、内容: \(comment.content)"
        }

        if comment.hasImage {
            label += "、画像付き"
        }

        return label
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - ShimmerModifier

private struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .clipped()
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - CommentComposeSection

struct CommentComposeSection: View {
    @Bindable var viewModel: CommentViewModel
    let currentUser: User?
    let isSubmitting: Bool
    let onSubmit: () -> Void
    let onImagePicker: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    AsyncImage(url: URL(string: currentUser?.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())

                    VStack(spacing: 8) {
                        TextField("コメントを追加...", text: $viewModel.commentText, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .lineLimit(1 ... 6)
                            .disabled(isSubmitting)

                        if let selectedImage = viewModel.selectedImage {
                            HStack {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 120)
                                    .cornerRadius(8)

                                VStack {
                                    Button(action: viewModel.removeSelectedImage) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                    }

                                    Spacer()
                                }
                            }
                        }

                        HStack {
                            Button(action: onImagePicker) {
                                Image(systemName: "photo")
                                    .foregroundColor(.blue)
                            }
                            .disabled(isSubmitting)

                            Spacer()

                            if !viewModel.commentText.isEmpty {
                                Text(viewModel.characterCountText)
                                    .font(.caption)
                                    .foregroundColor(viewModel.characterCountColor)
                            }

                            Button("投稿") {
                                onSubmit()
                            }
                            .disabled(!viewModel.canSubmit || isSubmitting)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                if let validationError = viewModel.validationError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)

                        Text(validationError)
                            .font(.caption)
                            .foregroundColor(.orange)

                        Spacer()
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGray6))
    }
}

// MARK: - PostDetailLoadingView

struct PostDetailLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)

            Text("投稿を読み込み中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - PostDetailErrorView

struct PostDetailErrorView: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text("投稿の読み込みに失敗しました")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("再試行", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

// MARK: - ImagePicker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
