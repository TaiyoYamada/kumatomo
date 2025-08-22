import SwiftUI

enum RouterDestination: Hashable {
	case myProfile
	case shopList
	case bookmarks
	case likes
	case coupons
	case settings
	case search
	case signUp
	case initialSetup
}

extension View {
	func withAppRouter() -> some View {
		navigationDestination(for: RouterDestination.self) { destination in
			switch destination {
			case .myProfile:
				MyProfileView()
			case .shopList:
				ShopListView()
			case .bookmarks:
				BookmarkListView()
			case .likes:
				LikeListView()
			case .coupons:
				CouponsView()
			case .settings:
				SettingsView()
			case .search:
				SearchView()
			case .signUp:
				SignUpView()
			case .initialSetup:
				InitialSetupView()
			}
		}
	}
}


