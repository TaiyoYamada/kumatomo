import Foundation

enum ReactionType: String, Codable, CaseIterable {
    case thumbsUp = "thumbsUp"
    case drooling = "drooling"
    case spicy = "spicy"
    
    var emoji: String {
        switch self {
        case .thumbsUp:
            return "👍"
        case .drooling:
            return "🤤"
        case .spicy:
            return "🌶️"
        }
    }
    
    var displayName: String {
        switch self {
        case .thumbsUp:
            return "いいね"
        case .drooling:
            return "美味しそう"
        case .spicy:
            return "辛そう"
        }
    }
}

struct PostReactions: Codable {
    var thumbsUp: Int
    var drooling: Int
    var spicy: Int
    
    enum CodingKeys: String, CodingKey {
        case thumbsUp = "thumbs_up"
        case drooling
        case spicy
    }
    
    init(thumbsUp: Int = 0, drooling: Int = 0, spicy: Int = 0) {
        self.thumbsUp = thumbsUp
        self.drooling = drooling
        self.spicy = spicy
    }
    
    func count(for reactionType: ReactionType) -> Int {
        switch reactionType {
        case .thumbsUp:
            return thumbsUp
        case .drooling:
            return drooling
        case .spicy:
            return spicy
        }
    }
    
    mutating func increment(_ reactionType: ReactionType) {
        switch reactionType {
        case .thumbsUp:
            thumbsUp += 1
        case .drooling:
            drooling += 1
        case .spicy:
            spicy += 1
        }
    }
    
    mutating func decrement(_ reactionType: ReactionType) {
        switch reactionType {
        case .thumbsUp:
            thumbsUp = max(0, thumbsUp - 1)
        case .drooling:
            drooling = max(0, drooling - 1)
        case .spicy:
            spicy = max(0, spicy - 1)
        }
    }
    
    var totalCount: Int {
        return thumbsUp + drooling + spicy
    }
}