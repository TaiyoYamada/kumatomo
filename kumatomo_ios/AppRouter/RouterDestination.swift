import SwiftUI

// MARK: - 画面遷移用のDestination enum
// 統合済み: 全ての画面遷移はこのenumで管理
enum RouterDestination: Hashable {
	case myProfile      // マイプロフィール画面
//	case shopList       // お店一覧画面
	case bookmarks      // ブックマーク画面
	case likes          // いいね一覧画面
	case coupons        // クーポン画面
	case settings       // 設定画面
	case search         // 検索画面
	case signUp         // サインアップ画面
	case initialSetup   // 初期設定画面
	case postDetail(postId: Int)  // 投稿詳細画面
	case likedPosts     // いいねした投稿一覧画面
	case bookmarkedPosts // ブックマークした投稿一覧画面
	case userProfile(userId: Int) // ユーザープロフィール画面
}

// MARK: - タブ選択用のenum（ContentViewから移動・統合）
// 旧: MainTabView.Selection -> TabSelection に統一
enum TabSelection: Hashable {
	case bulletinboard       // 掲示板タブ
	case search     // 検索タブ
	case portal     // ポータルタブ
	case kumamonAI  // くまモンAIタブ
	case profile    // プロフィールタブ
}

extension View {
	func withAppRouter() -> some View {
		navigationDestination(for: RouterDestination.self) { destination in
			switch destination {
			case .myProfile:
				MyProfileView()
//			case .shopList:
//				ShopListView()
			case .bookmarks:
				BookmarkedPostsView()
					.environmentObject(CurrentUserManager.shared)
			case .likes:
				LikedPostsView()
					.environmentObject(CurrentUserManager.shared)
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
			case .postDetail(let postId):
				PostDetailView(postId: postId)
					.environmentObject(CurrentUserManager.shared)
			case .likedPosts:
				LikedPostsView()
					.environmentObject(CurrentUserManager.shared)
			case .bookmarkedPosts:
				BookmarkedPostsView()
					.environmentObject(CurrentUserManager.shared)
			case .userProfile(let userId):
				UserProfileView(userId: userId)
					.environmentObject(CurrentUserManager.shared)
			}
		}
	}
	

}

// MARK: - Placeholder View for missing implementations
struct PlaceholderView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 48))
//                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("この機能は開発中です")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}




