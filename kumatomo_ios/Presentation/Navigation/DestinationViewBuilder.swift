import SwiftUI

// MARK: - DestinationViewBuilder

/// RouterDestination から対応する View を生成するビルダー
///
/// 環境は NavigationStack のルートで設定され、自動的に継承されるため、
/// このビルダーでは環境設定を行わない。
enum DestinationViewBuilder {

    /// 指定された destination に対応する View を生成
    /// - Parameter destination: ナビゲーション先
    /// - Returns: 対応する View
    @ViewBuilder
    static func view(for destination: RouterDestination) -> some View {
        switch destination {
        case .myProfile:
            MyProfileView()

        case .bookmarkedPosts:
            BookmarkedPostsView()

        case .likedPosts:
            LikedPostsView()

        case .settings:
            SettingsView()

        case .search:
            SearchView()

        case .signUp:
            SignUpView()

        case .initialSetup:
            InitialSetupView()

        case let .postDetail(postId):
            PostDetailView(postId: postId)

        case let .userProfile(userId):
            UserProfileView(userId: userId)

        case let .webView(url, title):
            InAppWebView(url: url, title: title)

        case let .announcementList(announcements):
            AnnouncementListView(announcements: announcements)

        case let .announcementDetail(announcement):
            AnnouncementDetailView(announcement: announcement)
        }
    }
}
