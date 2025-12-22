import Foundation

enum ShopCategory: String, CaseIterable, Identifiable, Sendable {
    case restaurant
    case cafe
    case bar
    case convenienceStore
    case superMarket
    case hospital
    case school
    case publicFacility
    case gym
    case entertainment
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .restaurant: "飲食"
        case .cafe: "カフェ"
        case .bar: "バー"
        case .convenienceStore: "コンビニ"
        case .superMarket: "スーパー・商業施設"
        case .hospital: "病院・クリニック"
        case .school: "学校・大学"
        case .publicFacility: "公共施設"
        case .gym: "ジム"
        case .entertainment: "娯楽・レジャー"
        case .other: "その他"
        }
    }

    var googlePlaceTypes: [String] {
        switch self {
        case .restaurant: ["restaurant"]
        case .cafe: ["cafe", "coffee_shop"]
        case .bar: ["bar"]
        case .convenienceStore: ["convenience_store"]
        case .superMarket: ["supermarket", "shopping_mall", "department_store"]
        case .hospital: ["hospital", "doctor", "dentist"]
        case .school: ["school", "university"]
        case .publicFacility: ["city_hall", "library", "local_government_office"]
        case .gym: ["gym"]
        case .entertainment: ["movie_theater", "amusement_park", "bowling_alley"]
        case .other: []
        }
    }
}
