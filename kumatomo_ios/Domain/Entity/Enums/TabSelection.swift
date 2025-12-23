import SwiftUI

// MARK: - TabSelection

/// アプリのタブ選択を表す enum
enum TabSelection: Hashable, Sendable {
    case bulletinboard // 掲示板タブ
    case shop // お店タブ
    case search // 検索タブ
    case portal // ポータルタブ
    case profile // プロフィールタブ
}
