import SwiftUI

// MARK: - AppRouter for programmatic navigation
@MainActor
class AppRouter: ObservableObject {
    // 現在選択中のタブ
    @Published var selectedTab: TabSelection = .portal

    // タブごとのNavigationPathを保持
    @Published private(set) var navigationPaths: [TabSelection: NavigationPath] = [
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
        var path = navigationPaths[targetTab] ?? NavigationPath()
        path.append(destination)
        navigationPaths[targetTab] = path
    }
    
    private func removeLast(from tab: TabSelection? = nil) {
        let targetTab = tab ?? selectedTab
        var path = navigationPaths[targetTab] ?? NavigationPath()
        if !path.isEmpty { path.removeLast() }
        navigationPaths[targetTab] = path
    }
    
    private func resetPath(for tab: TabSelection? = nil) {
        let targetTab = tab ?? selectedTab
        navigationPaths[targetTab] = NavigationPath()
    }
    
    // MARK: - Navigation Methods
    
    func navigateToPostDetail(postId: Int) {
        append(.postDetail(postId: postId))
    }
    
    func navigateToLikedPosts(on tab: TabSelection? = nil) {
        append(.likedPosts, to: tab)
    }
    
    func navigateToBookmarkedPosts(on tab: TabSelection? = nil) {
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
        append(destination, to: tab)
    }
    
    // MARK: - Deep Linking Support
    
    func handleDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            return
        }
        
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
            break
        }
    }
}
