import SwiftUI

// MARK: - 画面遷移用のDestination enum
// 統合済み: 全ての画面遷移はこのenumで管理
enum RouterDestination: Hashable {
	case myProfile      // マイプロフィール画面
	case shopList       // お店一覧画面
	case bookmarks      // ブックマーク画面
	case likes          // いいね一覧画面
	case coupons        // クーポン画面
	case settings       // 設定画面
	case search         // 検索画面
	case signUp         // サインアップ画面
	case initialSetup   // 初期設定画面
}

// MARK: - タブ選択用のenum（ContentViewから移動・統合）
// 旧: MainTabView.Selection -> TabSelection に統一
enum TabSelection: Hashable {
	case home     // ホームタブ
	case search   // 検索タブ
	case post     // 投稿タブ
	case portal   // ポータルタブ
	case profile  // プロフィールタブ
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


