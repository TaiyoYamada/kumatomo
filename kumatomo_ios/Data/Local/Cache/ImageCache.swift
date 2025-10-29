import Foundation
import UIKit

// Minimal image cache facade to support recovery actions
@MainActor
class ImageCache: ObservableObject {
    static let shared = ImageCache()
    private init() {}

    func clearCache() {
        // Clear URLCache (network image cache)
        URLCache.shared.removeAllCachedResponses()

        // Optionally clear in-memory UIImage caches if used elsewhere
        // This is a placeholder; integrate with your image caching solution if present
        print("🧹 Image cache cleared")
    }
}

