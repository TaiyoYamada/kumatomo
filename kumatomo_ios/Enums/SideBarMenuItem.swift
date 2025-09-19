import Foundation

// MARK: - Sidebar Menu Item Type
enum SidebarMenuItemType: CaseIterable {
    case kumamonAI, bookmarks, likes, coupons, notifications, help, contact, settings, logout
    
    var icon: String {
        switch self {
        case .kumamonAI: return "bubble.left.and.bubble.right"
        case .bookmarks: return "bookmark.fill"
        case .likes: return "heart.fill"
        case .coupons: return "ticket.fill"
        case .notifications: return "bell.fill"
        case .help: return "questionmark.circle.fill"
        case .contact: return "envelope.fill"
        case .settings: return "gearshape.fill"
        case .logout: return "rectangle.portrait.and.arrow.right"
        }
    }
    
    var title: String {
        switch self {
        case .kumamonAI: return "くまモンAI"
        case .bookmarks: return "ブックマーク"
        case .likes: return "いいね"
        case .coupons: return "クーポン"
        case .notifications: return "お知らせ"
        case .help: return "ヘルプ"
        case .contact: return "お問い合わせ"
        case .settings: return "設定"
        case .logout: return "ログアウト"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .kumamonAI: return "AIに相談する"
        case .bookmarks: return "保存した投稿"
        case .likes: return "いいねした投稿"
        case .coupons: return "利用可能なクーポン"
        case .settings: return "アプリの設定"
        case .logout: return "サインアウトします"
        case .notifications, .help, .contact: return nil
        }
    }
    
    var isExternalLink: Bool {
        switch self {
        case .notifications, .help, .contact: return true
        default: return false
        }
    }
    
    var externalURL: String? {
        switch self {
        case .notifications, .help, .contact: return "https://www.notion.so/"
        default: return nil
        }
    }
    
    var isPrimarySection: Bool {
        switch self {
        case .kumamonAI, .bookmarks, .likes, .coupons: return true
        default: return false
        }
    }
}


// MARK: - Extensions
extension SidebarMenuItemType: Identifiable {
    var id: String { title }
}
