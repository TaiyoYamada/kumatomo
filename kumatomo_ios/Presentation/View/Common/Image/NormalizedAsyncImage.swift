import SwiftUI

// MARK: - NormalizedAsyncImage

/// A wrapper around AsyncImage that normalizes image URLs using ImageURLNormalizer.
/// This ensures images work correctly when the API returns localhost URLs
/// and the app needs to connect via ngrok or other proxy.
struct NormalizedAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    init(
        urlString: String?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        let normalizedURL = ImageURLNormalizer.normalize(urlString)
        AsyncImage(url: normalizedURL) { phase in
            switch phase {
            case let .success(image):
                content(image)
            case .failure:
                placeholder()
            case .empty:
                placeholder()
            @unknown default:
                placeholder()
            }
        }
    }
}

// MARK: - Convenience initializer with default placeholder

extension NormalizedAsyncImage where Placeholder == Color {
    init(
        urlString: String?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.urlString = urlString
        self.content = content
        placeholder = { Color.gray.opacity(0.3) }
    }
}

// MARK: - Simple image initializer

extension NormalizedAsyncImage where Content == Image, Placeholder == Color {
    init(urlString: String?) {
        self.urlString = urlString
        content = { $0 }
        placeholder = { Color.gray.opacity(0.3) }
    }
}

#Preview {
    VStack {
        NormalizedAsyncImage(urlString: "/storage/test.jpg") { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            ProgressView()
        }
        .frame(width: 100, height: 100)
    }
}
