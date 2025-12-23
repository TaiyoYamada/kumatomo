import SwiftUI

// MARK: - DestinationViewBuilder
enum DestinationViewBuilder {

    @ViewBuilder
    static func view(for destination: RouterDestination) -> some View {
        switch destination {
        case .myProfile:
            MyProfileView()

        case .bookmarks, .bookmarkedPosts:
            BookmarkedPostsView()

        case .likes, .likedPosts:
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
        }
    }
}
