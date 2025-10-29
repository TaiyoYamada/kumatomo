import SwiftUI

enum ShopGenre: String, CaseIterable, Codable {
    case ramen = "ラーメン"
    case cafe = "カフェ"
    case izakaya = "居酒屋"
    case yakiniku = "焼肉"
    case sushi = "寿司"
    case sweets = "スイーツ"
    case fastFood = "ファストフード"
    case restaurant = "レストラン"
    case bar = "バー"
    case bakery = "ベーカリー"
    case italian = "イタリアン"
    case chinese = "中華"
    case korean = "韓国料理"
    case french = "フレンチ"
    case japanese = "和食"
    case western = "洋食"
    case seafood = "海鮮"
    case vegetarian = "ベジタリアン"
    case bbq = "BBQ"
    case other = "その他"
    
    var displayName: String {
        return rawValue
    }
    
    var color: Color {
        switch self {
        case .ramen:
            return Color(red: 0.8, green: 0.2, blue: 0.2) // Red
        case .cafe:
            return Color(red: 0.6, green: 0.4, blue: 0.2) // Brown
        case .izakaya:
            return Color(red: 0.9, green: 0.6, blue: 0.0) // Orange
        case .yakiniku:
            return Color(red: 0.7, green: 0.1, blue: 0.1) // Dark Red
        case .sushi:
            return Color(red: 0.0, green: 0.4, blue: 0.8) // Blue
        case .sweets:
            return Color(red: 0.9, green: 0.4, blue: 0.7) // Pink
        case .fastFood:
            return Color(red: 0.9, green: 0.7, blue: 0.0) // Yellow
        case .restaurant:
            return Color(red: 0.5, green: 0.3, blue: 0.7) // Purple
        case .bar:
            return Color(red: 0.2, green: 0.2, blue: 0.2) // Dark Gray
        case .bakery:
            return Color(red: 0.8, green: 0.6, blue: 0.4) // Light Brown
        case .italian:
            return Color(red: 0.0, green: 0.6, blue: 0.3) // Green
        case .chinese:
            return Color(red: 0.8, green: 0.0, blue: 0.0) // Bright Red
        case .korean:
            return Color(red: 0.6, green: 0.0, blue: 0.4) // Maroon
        case .french:
            return Color(red: 0.0, green: 0.3, blue: 0.6) // Navy Blue
        case .japanese:
            return Color(red: 0.4, green: 0.6, blue: 0.2) // Olive Green
        case .western:
            return Color(red: 0.7, green: 0.5, blue: 0.3) // Tan
        case .seafood:
            return Color(red: 0.0, green: 0.7, blue: 0.8) // Cyan
        case .vegetarian:
            return Color(red: 0.2, green: 0.8, blue: 0.2) // Bright Green
        case .bbq:
            return Color(red: 0.5, green: 0.2, blue: 0.0) // Dark Brown
        case .other:
            return Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
        }
    }
    
    /// Returns all genre cases as an array for easy iteration
    static var allGenres: [ShopGenre] {
        return ShopGenre.allCases
    }
    
    /// Returns the genre from a string value, case-insensitive
    static func from(string: String) -> ShopGenre? {
        return ShopGenre.allCases.first { $0.rawValue.lowercased() == string.lowercased() }
    }
}