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
            return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .cafe:
            return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .izakaya:
            return Color(red: 0.9, green: 0.6, blue: 0.0)
        case .yakiniku:
            return Color(red: 0.7, green: 0.1, blue: 0.1)
        case .sushi:
            return Color(red: 0.0, green: 0.4, blue: 0.8)
        case .sweets:
            return Color(red: 0.9, green: 0.4, blue: 0.7)
        case .fastFood:
            return Color(red: 0.9, green: 0.7, blue: 0.0)
        case .restaurant:
            return Color(red: 0.5, green: 0.3, blue: 0.7)
        case .bar:
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        case .bakery:
            return Color(red: 0.8, green: 0.6, blue: 0.4)
        case .italian:
            return Color(red: 0.0, green: 0.6, blue: 0.3)
        case .chinese:
            return Color(red: 0.8, green: 0.0, blue: 0.0)
        case .korean:
            return Color(red: 0.6, green: 0.0, blue: 0.4)
        case .french:
            return Color(red: 0.0, green: 0.3, blue: 0.6)
        case .japanese:
            return Color(red: 0.4, green: 0.6, blue: 0.2)
        case .western:
            return Color(red: 0.7, green: 0.5, blue: 0.3)
        case .seafood:
            return Color(red: 0.0, green: 0.7, blue: 0.8)
        case .vegetarian:
            return Color(red: 0.2, green: 0.8, blue: 0.2)
        case .bbq:
            return Color(red: 0.5, green: 0.2, blue: 0.0)
        case .other:
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }

    static var allGenres: [ShopGenre] {
        return ShopGenre.allCases
    }

    static func from(string: String) -> ShopGenre? {
        return ShopGenre.allCases.first { $0.rawValue.lowercased() == string.lowercased() }
    }
}