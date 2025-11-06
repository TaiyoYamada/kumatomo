import SwiftUI

struct PostImagesGridView: View {
    let images: [PostImage]

    init(imageUrls: [String]) {
        self.images = imageUrls.enumerated().map { index, url in
            PostImage(id: index, postId: 0, imageUrl: url, displayOrder: index + 1)
        }
    }

    init(images: [PostImage]) {
        self.images = images
    }

    private var imageUrls: [String] {
        return images.map { $0.imageUrl }
    }

    var body: some View {
        Group {
            switch images.count {
            case 1:
                SingleImageView(imageURL: imageUrls[0])
            case 2:
                TwoImagesView(images: imageUrls)
            case 3:
                ThreeImagesView(images: imageUrls)
            case 4:
                FourImagesView(images: imageUrls)
            default:
                MultipleImagesView(images: Array(imageUrls.prefix(4)))
            }
        }
    }
}


struct SingleImageView: View {
    let imageURL: String

    var body: some View {
        AsyncImage(url: URL(string: imageURL)) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        ProgressView()
                            .tint(.secondary)
                    )
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 300)
                    .clipped()
            case .failure(_):
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    )
            @unknown default:
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .aspectRatio(16/9, contentMode: .fit)
            }
        }
    }
}


struct TwoImagesView: View {
    let images: [String]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(images.count, 2), id: \.self) { index in
                AsyncImage(url: URL(string: images[index])) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.secondary)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 200)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .frame(maxHeight: 200)
    }
}


struct ThreeImagesView: View {
    let images: [String]

    var body: some View {
        HStack(spacing: 2) {
            AsyncImage(url: URL(string: images[0])) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.secondary)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                case .failure(_):
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        )
                @unknown default:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                ForEach(1..<min(images.count, 3), id: \.self) { index in
                    AsyncImage(url: URL(string: images[index])) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .tint(.secondary)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        case .failure(_):
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 200)
    }
}


struct FourImagesView: View {
    let images: [String]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 2), spacing: 2) {
            ForEach(0..<min(images.count, 4), id: \.self) { index in
                AsyncImage(url: URL(string: images[index])) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.secondary)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
}


struct MultipleImagesView: View {
    let images: [String]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 2), spacing: 2) {
            ForEach(0..<min(images.count, 3), id: \.self) { index in
                AsyncImage(url: URL(string: images[index])) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.secondary)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }

            if images.count > 4 {
                ZStack {
                    AsyncImage(url: URL(string: images[3])) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                        default:
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }

                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .overlay(
                            Text("+\(images.count - 3)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }
}


#if DEBUG
struct PostImagesGridView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PostImagesGridView(imageUrls: ["https://example.com/image1.jpg"])
            PostImagesGridView(imageUrls: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"])
            PostImagesGridView(imageUrls: ["https://example.com/image1.jpg", "https://example.com/image2.jpg", "https://example.com/image3.jpg"])
            PostImagesGridView(imageUrls: ["https://example.com/image1.jpg", "https://example.com/image2.jpg", "https://example.com/image3.jpg", "https://example.com/image4.jpg"])
        }
        .padding()
    }
}
#endif