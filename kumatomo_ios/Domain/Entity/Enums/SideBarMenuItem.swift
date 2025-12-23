import Foundation

// MARK: - SidebarMenuItemType

enum SidebarMenuItemType: CaseIterable {
    case bookmarks, likes, help, contact, settings, logout

    var icon: String {
        switch self {
        case .bookmarks: return "bookmark.fill"
        case .likes: return "heart.fill"
        case .help: return "questionmark.circle.fill"
        case .contact: return "envelope.fill"
        case .settings: return "gearshape.fill"
        case .logout: return "rectangle.portrait.and.arrow.right"
        }
    }

    var title: String {
        switch self {
        case .bookmarks: return "ブックマーク"
        case .likes: return "いいね"
        case .help: return "ヘルプ"
        case .contact: return "お問い合わせ"
        case .settings: return "設定"
        case .logout: return "ログアウト"
        }
    }

    var subtitle: String? {
        switch self {
        case .bookmarks: return "保存した投稿"
        case .likes: return "いいねした投稿"
        case .settings: return "アプリの設定"
        case .logout: return "サインアウトします"
        case .help, .contact: return nil
        }
    }

    var externalURL: String? {
        switch self {
        case .help, .contact: return "https://www.notion.so/274db424e42280019ed4d3cbbcd9540d"
        default: return nil
        }
    }

    var isPrimarySection: Bool {
        switch self {
        case .bookmarks, .likes: return true
        default: return false
        }
    }
}

// MARK: Identifiable

extension SidebarMenuItemType: Identifiable {
    var id: String { title }
}
