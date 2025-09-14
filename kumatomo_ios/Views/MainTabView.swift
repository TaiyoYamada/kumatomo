import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: AuthViewModel
    @StateObject private var bulletinBoardViewModel = BulletinBoardViewModel()
    @StateObject private var userManager = CurrentUserManager.shared
    @StateObject private var sidebarState = SidebarState()
    @StateObject private var appRouter = AppRouter.shared

    var body: some View {
        SidebarContainer(isPresented: $sidebarState.isPresented, user: userManager.currentUser) {
            TabView(selection: $appRouter.selectedTab) {
                NavigationStack(path: appRouter.pathBinding(for: .home)) {
                    HomeView()
                        .environmentObject(bulletinBoardViewModel)
                        .environmentObject(userManager)
                        .environmentObject(sidebarState)
                        .environment(\.openSidebar, sidebarState.open)
                        .withAppRouter()
                        .navigationTitle("ホーム")
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(TabSelection.home)
                
                NavigationStack(path: appRouter.pathBinding(for: .search)) {
                    SearchView()
                        .environmentObject(userManager)
                        .environmentObject(sidebarState)
                        .environment(\.openSidebar, sidebarState.open)
                        .withAppRouter()
                        .navigationTitle("検索")
                }
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("検索")
                }
                .tag(TabSelection.search)
                
                NavigationStack(path: appRouter.pathBinding(for: .portal)) {
                    PortalView()
                        .environmentObject(userManager)
                        .environmentObject(sidebarState)
                        .environment(\.openSidebar, sidebarState.open)
                        .withAppRouter()
                    // ★ navigationTitleとtoolbarはここでは設定しない
                }
                .tabItem {
                    Image(systemName: "rectangle.grid.2x2")
                    Text("ポータル")
                }
                .tag(TabSelection.portal)
                
                KumamonAIView()
                    .environmentObject(userManager)
                    .environmentObject(sidebarState)
                    .environment(\.openSidebar, sidebarState.open)
                    .tabItem {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("くまモンAI")
                    }
                    .tag(TabSelection.kumamonAI)
                
                MyProfileView()
                    .environmentObject(userManager)
                    .environmentObject(sidebarState)
                    .environment(\.openSidebar, sidebarState.open)
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                        Text("プロフィール")
                    }
                    .tag(TabSelection.profile)
            }
            .accentColor(Color.primaryOrange)
        }
        .errorOverlay()
        .onAppear {
            userManager.loadCurrentUser()
        }
        .onOpenURL { url in
            appRouter.handleDeepLink(url: url)
        }
    }
}
