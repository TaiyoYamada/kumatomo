import Foundation
import SwiftUI

enum CategoryType: String, Codable, CaseIterable {
    case gourmet = "グルメ"
    case event = "イベント"
    case emergency = "緊急"
    case other = "その他"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .gourmet:
            return Color(hex: "10B981") // Green
        case .event:
            return Color(hex: "F59E0B") // Orange
        case .emergency:
            return Color(hex: "EF4444") // Red
        case .other:
            return Color(hex: "8B5CF6") // Purple
        }
    }
    
    var icon: String {
        switch self {
        case .gourmet:
            return "fork.knife"
        case .event:
            return "calendar"
        case .emergency:
            return "exclamationmark.triangle"
        case .other:
            return "tag"
        }
    }
}

