import SwiftUI

// MARK: - PostUserImageView

struct PostUserImageView: View {
    let imageURL: String?
    let size: CGFloat

    init(imageURL: String?, size: CGFloat = 44) {
        self.imageURL = imageURL
        self.size = size
    }

    var body: some View {
        Group {
            if let imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.secondary)
                            )
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: size * 0.4))
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: size * 0.4))
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.secondary)
                    )
                    .frame(width: size, height: size)
            }
        }
    }
}

#if DEBUG
struct PostUserImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PostUserImageView(imageURL: nil, size: 44)
            PostUserImageView(imageURL: "https://example.com/image.jpg", size: 60)
            PostUserImageView(imageURL: "", size: 32)
        }
        .padding()
    }
}
#endif
