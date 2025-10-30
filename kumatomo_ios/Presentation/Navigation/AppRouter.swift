import SwiftUI
import Observation

// MARK: - AppRouter for programmatic navigation
@MainActor
@Observable
class AppRouter {
    // 現在選択中のタブ
    var selectedTab: TabSelection = .portal

    // タブごとのNavigationPathを保持
    private(set) var navigationPaths: [TabSelection: NavigationPath] = [
        .bulletinboard: NavigationPath(),
        .search: NavigationPath(),
        .portal: NavigationPath(),
        .shop: NavigationPath(),
        .profile: NavigationPath()
    ]
    
    static let shared = AppRouter()
    
    private init() {}
    
    // MARK: - Path Binding per Tab
    func pathBinding(for tab: TabSelection) -> Binding<NavigationPath> {
        Binding(
            get: { [weak self] in
                guard let self else { return NavigationPath() }
                return self.navigationPaths[tab] ?? NavigationPath()
            },
            set: { [weak self] newValue in
                self?.navigationPaths[tab] = newValue
            }
        )
    }
    
    // MARK: - Helpers
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
    
    // MARK: - Navigation Methods
    
    func navigateToPostDetail(postId: Int) {
        print("[AppRouter] navigateToPostDetail id=\(postId) currentTab=\(selectedTab)")
        append(.postDetail(postId: postId))
    }
    
    func navigateToShopDetail(shopId: Int) {
        print("[AppRouter] navigateToShopDetail id=\(shopId) currentTab=\(selectedTab)")
        append(.shopDetail(shopId: shopId))
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
//    
//    func navigateToShopList() {
//        append(.shopList)
//    }
    
    func navigateToSettings(on tab: TabSelection? = nil) {
        append(.settings, to: tab)
    }
    
    func navigateToSearch(on tab: TabSelection? = nil) {
        append(.search, to: tab)
    }
    
    // MARK: - Navigation Control
    
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
    
    // MARK: - Deep Linking Support
    
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
                // Open posts under portal tab for consistency
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
//        case "shops":
//            navigateToShopList()
        case "settings":
            selectedTab = .portal
            navigateToSettings(on: .portal)
        default:
            print("[AppRouter] deep link not handled: \(host)")
            break
        }
    }
}
