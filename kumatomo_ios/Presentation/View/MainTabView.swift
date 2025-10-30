import SwiftUI
import Observation

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @State private var bulletinBoardViewModel = BulletinBoardViewModel()
    @State private var userManager = CurrentUserManager.shared
    @State private var sidebarState = SidebarState()
    @State private var appRouter = AppRouter.shared

    var body: some View {
        SidebarContainer(isPresented: $sidebarState.isPresented, user: userManager.currentUser) {
            TabView(selection: $appRouter.selectedTab) {
                NavigationStack(path: appRouter.pathBinding(for: .bulletinboard)) {
                    BulletinBoardView()
                        .environment(bulletinBoardViewModel)
                        .environment(userManager)
                        .environment(sidebarState)
                        .environment(\.openSidebar, sidebarState.open)
                        .withAppRouter()
                        .navigationTitle("ホーム")
                        .appNavigationStyle()
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(TabSelection.bulletinboard)
                
                NavigationStack(path: appRouter.pathBinding(for: .search)) {
                    SearchView()
                        .environment(userManager)
                        .environment(sidebarState)
                        .environment(\.openSidebar, sidebarState.open)
                        .withAppRouter()
                        .navigationTitle("検索")
                        .appNavigationStyle()
                }
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("検索")
                }
                .tag(TabSelection.search)
                
                NavigationStack(path: appRouter.pathBinding(for: .portal)) {
                    PortalView()
                        .withAppRouter() // Attach destination to stack content to ensure resolution
                    // ★ navigationTitleとtoolbarはここでは設定しない
                }
                .appNavigationStyle()
                .environment(userManager)
                .environment(sidebarState)
                .environment(\.openSidebar, sidebarState.open)
                .tabItem {
                    Image(systemName: "rectangle.grid.2x2")
                    Text("ポータル")
                }
                .tag(TabSelection.portal)
                
                // お店一覧タブ
                NavigationStack(path: appRouter.pathBinding(for: .shop)) {
                    ShopListView()
                        .environment(userManager)
                        .environment(sidebarState)
                        .environment(\.openSidebar, sidebarState.open)
                        .withAppRouter()
                        .navigationTitle("お店一覧")
                        .appNavigationStyle()
                }
                .environment(appRouter)
                .tabItem {
                    Image(systemName: "storefront.fill")
                    Text("お店")
                }
                .tag(TabSelection.shop)
                
                NavigationStack(path: appRouter.pathBinding(for: .profile)) {
                    MyProfileView()
                        .environment(userManager)
                        .environment(sidebarState)
                        .environment(\.openSidebar, sidebarState.open)
                        .withAppRouter()
                        .navigationTitle("プロフィール")
                        .appNavigationStyle()
                }
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("プロフィール")
                }
                .tag(TabSelection.profile)
            }
            .accentColor(Color.primaryOrange)
        }
        .onAppear {
            userManager.loadCurrentUser()
        }
        .onOpenURL { url in
            appRouter.handleDeepLink(url: url)
        }
    }
}
