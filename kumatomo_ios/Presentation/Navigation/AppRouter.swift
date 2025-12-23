import SwiftUI
import Observation

// MARK: - AppRouter

/// アプリのナビゲーション状態を管理するルーター
///
/// 各タブの NavigationPath を管理し、プログラム的なナビゲーションと
/// ディープリンクのハンドリングを提供する。
@MainActor
@Observable
final class AppRouter {

    // MARK: - Properties

    /// 現在選択中のタブ
    var selectedTab: TabSelection = .portal

    /// タブごとのナビゲーションパス
    private(set) var navigationPaths: [TabSelection: NavigationPath] = [
        .bulletinboard: NavigationPath(),
        .shop: NavigationPath(),
        .search: NavigationPath(),
        .portal: NavigationPath(),
        .profile: NavigationPath()
    ]

    // MARK: - Singleton（後方互換性のため維持、DI推奨）

    static let shared = AppRouter()

    // MARK: - Initialization

    /// DI Container 経由での初期化用
    init() {}

    // MARK: - Path Binding

    /// 指定タブの NavigationPath への Binding を取得
    /// - Parameter tab: 対象タブ
    /// - Returns: NavigationPath への Binding
    func pathBinding(for tab: TabSelection) -> Binding<NavigationPath> {
        Binding(
            get: { [weak self] in
                self?.navigationPaths[tab] ?? NavigationPath()
            },
            set: { [weak self] newValue in
                self?.navigationPaths[tab] = newValue
            }
        )
    }

    // MARK: - Navigation

    /// 指定された destination へナビゲート
    /// - Parameters:
    ///   - destination: ナビゲーション先
    ///   - tab: 対象タブ（nil の場合は現在のタブ）
    func navigate(to destination: RouterDestination, on tab: TabSelection? = nil) {
        let targetTab = tab ?? selectedTab
        var path = navigationPaths[targetTab] ?? NavigationPath()
        path.append(destination)
        navigationPaths[targetTab] = path
    }

    /// 1つ前の画面に戻る
    /// - Parameter tab: 対象タブ（nil の場合は現在のタブ）
    func goBack(on tab: TabSelection? = nil) {
        let targetTab = tab ?? selectedTab
        guard var path = navigationPaths[targetTab], !path.isEmpty else { return }
        path.removeLast()
        navigationPaths[targetTab] = path
    }

    /// ルート画面まで戻る
    /// - Parameter tab: 対象タブ（nil の場合は現在のタブ）
    func popToRoot(on tab: TabSelection? = nil) {
        let targetTab = tab ?? selectedTab
        navigationPaths[targetTab] = NavigationPath()
    }

    // MARK: - Deep Link

    /// ディープリンクをハンドリング
    /// - Parameter url: ディープリンク URL
    func handleDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            return
        }

        switch host {
        case "post":
            if let postIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let postId = Int(postIdString) {
                selectedTab = .portal
                navigate(to: .postDetail(postId: postId), on: .portal)
            }

        case "user":
            if let userIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let userId = Int(userIdString) {
                selectedTab = .portal
                navigate(to: .userProfile(userId: userId), on: .portal)
            }

        case "liked-posts":
            selectedTab = .portal
            navigate(to: .likedPosts, on: .portal)

        case "bookmarked-posts":
            selectedTab = .portal
            navigate(to: .bookmarkedPosts, on: .portal)

        case "profile":
            selectedTab = .portal
            navigate(to: .myProfile, on: .portal)

        case "settings":
            selectedTab = .portal
            navigate(to: .settings, on: .portal)

        default:
            break
        }
    }
}
