import SwiftUI

// MARK: - RouterDestination

/// ナビゲーション先を表す enum
enum RouterDestination: Hashable, Sendable {
    case myProfile // マイプロフィール画面
    case bookmarkedPosts // ブックマークした投稿一覧画面
    case likedPosts // いいねした投稿一覧画面
    case settings // 設定画面
    case search // 検索画面
    case signUp // サインアップ画面
    case initialSetup // 初期設定画面
    case postDetail(postId: Int) // 投稿詳細画面
    case userProfile(userId: Int) // ユーザープロフィール画面
    case webView(url: URL, title: String) // アプリ内Webビュー
    case announcementList(announcements: [Announcement]) // お知らせ一覧画面
    case announcementDetail(announcement: Announcement) // お知らせ詳細画面
}
