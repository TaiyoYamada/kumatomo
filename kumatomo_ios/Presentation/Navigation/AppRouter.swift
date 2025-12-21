import SwiftUI
import Observation

@MainActor
@Observable
class AppRouter {
    // 現在選択中のタブ
    var selectedTab: TabSelection = .portal

    private(set) var navigationPaths: [TabSelection: NavigationPath] = [
        .bulletinboard: NavigationPath(),
        .shop: NavigationPath(),
        .search: NavigationPath(),
        .portal: NavigationPath(),
        .profile: NavigationPath()
    ]

    static let shared = AppRouter()

    private init() {}

    func pathBinding(for tab: TabSelection) -> Binding<NavigationPath> {
        Binding(
            get: { [weak self] in
                guard let self else { return NavigationPath() }
                return navigationPaths[tab] ?? NavigationPath()
            },
            set: { [weak self] newValue in
                self?.navigationPaths[tab] = newValue
            }
        )
    }

    private func append(_ destination: RouterDestination, to tab: TabSelection? = nil) {
        let targetTab = tab ?? selectedTab
        print("[AppRouter] append destination=\(destination) to tab=\(targetTab)")
        var path = navigationPaths[targetTab] ?? NavigationPath()
        print("[AppRouter] before append path.count=\(path.count)")
        path.append(destination)
        navigationPaths[targetTab] = path
        print("[AppRouter] after append path.count=\(path.count)")
    }

    private func removeLast(from tab: TabSelection? = nil) {
        let targetTab = tab ?? selectedTab
        var path = navigationPaths[targetTab] ?? NavigationPath()
        print("[AppRouter] removeLast on tab=\(targetTab) path.count(before)=\(path.count)")
        if !path.isEmpty { path.removeLast() }
        navigationPaths[targetTab] = path
        print("[AppRouter] path.count(after)=\(path.count)")
    }

    private func resetPath(for tab: TabSelection? = nil) {
        let targetTab = tab ?? selectedTab
        print("[AppRouter] resetPath for tab=\(targetTab)")
        navigationPaths[targetTab] = NavigationPath()
    }

    func navigateToPostDetail(postId: Int) {
        print("[AppRouter] navigateToPostDetail id=\(postId) currentTab=\(selectedTab)")
        append(.postDetail(postId: postId))
    }

    func navigateToLikedPosts(on tab: TabSelection? = nil) {
        print("[AppRouter] navigateToLikedPosts requested on tab=\(tab.self ?? selectedTab)")
        append(.likedPosts, to: tab)
    }

    func navigateToBookmarkedPosts(on tab: TabSelection? = nil) {
        print("[AppRouter] navigateToBookmarkedPosts requested on tab=\(tab.self ?? selectedTab)")
        append(.bookmarkedPosts, to: tab)
    }

    func navigateToUserProfile(userId: Int, on tab: TabSelection? = nil) {
        append(.userProfile(userId: userId), to: tab)
    }

    func navigateToMyProfile(on tab: TabSelection? = nil) {
        append(.myProfile, to: tab)
    }

    func navigateToSettings(on tab: TabSelection? = nil) {
        append(.settings, to: tab)
    }

    func navigateToSearch(on tab: TabSelection? = nil) {
        append(.search, to: tab)
    }

    func goBack() {
        removeLast()
    }

    func popToRoot() {
        resetPath()
    }

    func navigate(to destination: RouterDestination, on tab: TabSelection? = nil) {
        let targetTab = tab ?? selectedTab
        print("[AppRouter] navigate to destination=\(destination) on tab=\(targetTab)")
        append(destination, to: targetTab)
    }

    func handleDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            return
        }
        print("[AppRouter] handleDeepLink host=\(host) query=\(components.queryItems ?? [])")

        switch host {
        case "post":
            if let postIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let postId = Int(postIdString) {
                selectedTab = .portal
                append(.postDetail(postId: postId), to: .portal)
            }
        case "user":
            if let userIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let userId = Int(userIdString) {
                selectedTab = .portal
                navigateToUserProfile(userId: userId, on: .portal)
            }
        case "liked-posts":
            selectedTab = .portal
            navigateToLikedPosts(on: .portal)
        case "bookmarked-posts":
            selectedTab = .portal
            navigateToBookmarkedPosts(on: .portal)
        case "profile":
            selectedTab = .portal
            navigateToMyProfile(on: .portal)
        case "settings":
            selectedTab = .portal
            navigateToSettings(on: .portal)
        default:
            print("[AppRouter] deep link not handled: \(host)")
        }
    }
}
