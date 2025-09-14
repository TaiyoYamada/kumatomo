import SwiftUI

// MARK: - AppRouter for programmatic navigation
@MainActor
class AppRouter: ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    static let shared = AppRouter()
    
    private init() {}
    
    // MARK: - Navigation Methods
    
    func navigateToPostDetail(postId: Int) {
        navigationPath.append(RouterDestination.postDetail(postId: postId))
    }
    
    func navigateToLikedPosts() {
        navigationPath.append(RouterDestination.likedPosts)
    }
    
    func navigateToBookmarkedPosts() {
        navigationPath.append(RouterDestination.bookmarkedPosts)
    }
    
    func navigateToUserProfile(userId: Int) {
        navigationPath.append(RouterDestination.userProfile(userId: userId))
    }
    
    func navigateToMyProfile() {
        navigationPath.append(RouterDestination.myProfile)
    }
    
    func navigateToShopList() {
        navigationPath.append(RouterDestination.shopList)
    }
    
    func navigateToSettings() {
        navigationPath.append(RouterDestination.settings)
    }
    
    func navigateToSearch() {
        navigationPath.append(RouterDestination.search)
    }
    
    // MARK: - Navigation Control
    
    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    func navigate(to destination: RouterDestination) {
        navigationPath.append(destination)
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
                navigateToPostDetail(postId: postId)
            }
        case "user":
            if let userIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let userId = Int(userIdString) {
                navigateToUserProfile(userId: userId)
            }
        case "liked-posts":
            navigateToLikedPosts()
        case "bookmarked-posts":
            navigateToBookmarkedPosts()
        case "profile":
            navigateToMyProfile()
        case "shops":
            navigateToShopList()
        case "settings":
            navigateToSettings()
        default:
            break
        }
    }
}