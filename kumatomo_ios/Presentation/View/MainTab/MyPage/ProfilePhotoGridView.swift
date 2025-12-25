import SwiftUI

// MARK: - ProfilePhotoGridView

/// プロフィール画面の写真タブ用グリッドビュー
/// 画像付き投稿のみを3列グリッドで表示（Instagram風）
struct ProfilePhotoGridView: View {
    let posts: [Post]
    let loading: Bool
    let onLoadMore: () -> Void

    @Environment(AppRouter.self) private var appRouter

    /// 画像付き投稿のみをフィルタリング
    private var photoPosts: [Post] {
        posts.filter { post in
            if let images = post.images, !images.isEmpty {
                return true
            }
            return false
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        if loading, photoPosts.isEmpty {
            loadingView
        } else if photoPosts.isEmpty {
            emptyStateView
        } else {
            photoGridContent
        }
    }

    // MARK: - Grid Content

    private var photoGridContent: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(photoPosts) { post in
                PhotoGridCell(post: post) {
                    appRouter.navigate(to: .postDetail(postId: post.id))
                }
                .onAppear {
                    // 最後の投稿が表示されたら追加読み込み
                    if post.id == photoPosts.last?.id {
                        onLoadMore()
                    }
                }
            }
        }
        .padding(.horizontal, 1)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("読み込み中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                Text("まだ写真がありません")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("画像付きの投稿をすると\nここに表示されます")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - PhotoGridCell

private struct PhotoGridCell: View {
    let post: Post
    let onTap: () -> Void

    /// 投稿の最初の画像URLを取得
    private var firstImageURL: String? {
        post.images?.first?.imageUrl
    }

    /// 複数画像かどうか
    private var hasMultipleImages: Bool {
        (post.images?.count ?? 0) > 1
    }

    var body: some View {
        Button(action: onTap) {
            GeometryReader { geometry in
                ZStack(alignment: .topTrailing) {
                    // メイン画像
                    if let imageURL = firstImageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .tint(.secondary)
                                    )
                            case let .success(image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.width)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 20))
                                            .foregroundColor(.secondary)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color(.systemGray5))
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                    }

                    // 複数画像インジケータ
                    if hasMultipleImages {
                        MultipleImagesIndicator()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MultipleImagesIndicator

private struct MultipleImagesIndicator: View {
    var body: some View {
        Image(systemName: "square.fill.on.square.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            .padding(8)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        ScrollView {
            ProfilePhotoGridView(
                posts: [],
                loading: false,
                onLoadMore: {}
            )
        }
        .environment(AppRouter.shared)
    }
}
#endif
