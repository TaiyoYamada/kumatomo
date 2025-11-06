import Foundation
import UIKit

@MainActor
class ImageCache: ObservableObject {
    static let shared = ImageCache()
    private init() {}

    func clearCache() {
        URLCache.shared.removeAllCachedResponses()

        print("🧹 Image cache cleared")
    }
}

