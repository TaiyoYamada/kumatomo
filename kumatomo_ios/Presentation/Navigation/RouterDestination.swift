import SwiftUI

// MARK: - RouterDestination

enum RouterDestination: Hashable {
    case myProfile // マイプロフィール画面
    case bookmarks // ブックマーク画面
    case likes // いいね一覧画面
    case coupons // クーポン画面
    case settings // 設定画面
    case search // 検索画面
    case signUp // サインアップ画面
    case initialSetup // 初期設定画面
    case postDetail(postId: Int) // 投稿詳細画面
    case likedPosts // いいねした投稿一覧画面
    case bookmarkedPosts // ブックマークした投稿一覧画面
    case userProfile(userId: Int) // ユーザープロフィール画面
}

// MARK: - TabSelection

enum TabSelection: Hashable {
    case bulletinboard // 掲示板タブ
    case shop // お店タブ
    case search // 検索タブ
    case portal // ポータルタブ
    case profile // プロフィールタブ
}

extension View {
    func withAppRouter() -> some View {
        navigationDestination(for: RouterDestination.self) { destination in
            switch destination {
            case .myProfile:
                MyProfileView()
            case .bookmarks:
                BookmarkedPostsView()
                    .environment(CurrentUserManager.shared)
            case .likes:
                LikedPostsView()
                    .environment(CurrentUserManager.shared)
            case .coupons:
                PlaceholderView(title: "クーポン")
            case .settings:
                PlaceholderView(title: "設定")
            case .search:
                SearchView()
            case .signUp:
                SignUpView()
            case .initialSetup:
                InitialSetupView()
            case let .postDetail(postId):
                PostDetailView(postId: postId)
                    .environment(CurrentUserManager.shared)
            case .likedPosts:
                LikedPostsView()
                    .environment(CurrentUserManager.shared)
            case .bookmarkedPosts:
                BookmarkedPostsView()
                    .environment(CurrentUserManager.shared)
            case let .userProfile(userId):
                UserProfileView(userId: userId)
                    .environment(CurrentUserManager.shared)
            }
        }
    }

}

// MARK: - PlaceholderView

struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hammer.and.wrench")
                .font(.system(size: 48))
                .foregroundColor(.primaryOrange)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text("この機能は開発中です")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("近日公開予定です")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
