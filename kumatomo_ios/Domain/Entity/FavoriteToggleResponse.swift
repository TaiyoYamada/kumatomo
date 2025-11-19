import Foundation

struct FavoriteToggleResponse: Codable {
    let favorited: Bool
    let message: String?
}