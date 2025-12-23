import SwiftUI

// MARK: - PostImagesGridView

/// 投稿画像のグリッド表示
/// タップでフルスクリーンビューワーを起動
struct PostImagesGridView: View {
    let images: [PostImage]
    let onImageTap: ((Int) -> Void)?

    @State private var showFullScreenViewer = false
    @State private var selectedImageIndex = 0

    init(imageUrls: [String], onImageTap: ((Int) -> Void)? = nil) {
        images = imageUrls.enumerated().map { index, url in
            PostImage(id: index, postId: 0, imageUrl: url, displayOrder: index + 1)
        }
        self.onImageTap = onImageTap
    }

    init(images: [PostImage], onImageTap: ((Int) -> Void)? = nil) {
        self.images = images
        self.onImageTap = onImageTap
    }

    private var imageUrls: [String] {
        return images.map(\.imageUrl)
    }

    var body: some View {
        Group {
            switch images.count {
            case 1:
                SingleImageGridItem(imageURL: imageUrls[0]) {
                    handleImageTap(index: 0)
                }
            case 2:
                TwoImagesGridView(images: imageUrls, onTap: handleImageTap)
            case 3:
                ThreeImagesGridView(images: imageUrls, onTap: handleImageTap)
            case 4:
                FourImagesGridView(images: imageUrls, onTap: handleImageTap)
            default:
                MultipleImagesGridView(
                    images: imageUrls,
                    totalCount: images.count,
                    onTap: handleImageTap
                )
            }
        }
        .cornerRadius(12)
        .fullScreenCover(isPresented: $showFullScreenViewer) {
            FullScreenImageViewer(
                imageURLs: imageUrls,
                startIndex: selectedImageIndex,
                onDismiss: { showFullScreenViewer = false }
            )
        }
    }

    private func handleImageTap(index: Int) {
        if let onImageTap {
            onImageTap(index)
        } else {
            selectedImageIndex = index
            showFullScreenViewer = true
        }
    }
}

// MARK: - SingleImageGridItem

struct SingleImageGridItem: View {
    let imageURL: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .overlay(ProgressView().tint(.secondary))
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: 300)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                        )
                @unknown default:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .aspectRatio(16 / 9, contentMode: .fit)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - TwoImagesGridView

struct TwoImagesGridView: View {
    let images: [String]
    let onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< min(images.count, 2), id: \.self) { index in
                Button { onTap(index) } label: {
                    GridImageCell(imageURL: images[index])
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(height: 200)
    }
}

// MARK: - ThreeImagesGridView

struct ThreeImagesGridView: View {
    let images: [String]
    let onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 2) {
            Button { onTap(0) } label: {
                GridImageCell(imageURL: images[0])
            }
            .buttonStyle(ScaleButtonStyle())

            VStack(spacing: 2) {
                ForEach(1 ..< min(images.count, 3), id: \.self) { index in
                    Button { onTap(index) } label: {
                        GridImageCell(imageURL: images[index])
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .frame(height: 200)
    }
}

// MARK: - FourImagesGridView

struct FourImagesGridView: View {
    let images: [String]
    let onTap: (Int) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        GeometryReader { geometry in
            let itemSize = (geometry.size.width - 2) / 2

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0 ..< min(images.count, 4), id: \.self) { index in
                    Button { onTap(index) } label: {
                        GridImageCell(imageURL: images[index])
                            .frame(width: itemSize, height: itemSize)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - MultipleImagesGridView

struct MultipleImagesGridView: View {
    let images: [String]
    let totalCount: Int
    let onTap: (Int) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        GeometryReader { geometry in
            let itemSize = (geometry.size.width - 2) / 2

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0 ..< 3, id: \.self) { index in
                    Button { onTap(index) } label: {
                        GridImageCell(imageURL: images[index])
                            .frame(width: itemSize, height: itemSize)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                // 4番目: 残り枚数オーバーレイ
                Button { onTap(3) } label: {
                    ZStack {
                        GridImageCell(imageURL: images[3])

                        if totalCount > 4 {
                            Rectangle()
                                .fill(.black.opacity(0.6))
                                .overlay(
                                    Text("+\(totalCount - 3)")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(width: itemSize, height: itemSize)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - GridImageCell

struct GridImageCell: View {
    let imageURL: String

    var body: some View {
        AsyncImage(url: URL(string: imageURL)) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(ProgressView().scaleEffect(0.6).tint(.secondary))
            case let .success(image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            case .failure:
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    )
            @unknown default:
                Rectangle().fill(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - ScaleButtonStyle

/// タップ時のスケールアニメーション
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#if DEBUG
struct PostImagesGridView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PostImagesGridView(imageUrls: ["https://example.com/image1.jpg"])
            PostImagesGridView(imageUrls: [
                "https://example.com/image1.jpg",
                "https://example.com/image2.jpg"
            ])
        }
        .padding()
    }
}
#endif
