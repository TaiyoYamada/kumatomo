import SwiftUI
import Observation
import Factory

// MARK: - MainTabView

struct MainTabView: View {

    // MARK: - Environment & State

    @Environment(AuthViewModel.self) private var viewModel
    @State private var bulletinBoardViewModel = BulletinBoardViewModel()
    @State private var userManager = CurrentUserManager.shared
    @State private var sidebarState = SidebarState()
    @State private var appRouter = Container.shared.appRouter()

    // MARK: - Body

    var body: some View {
        SidebarContainer(isPresented: $sidebarState.isPresented, user: userManager.currentUser) {
            TabView(selection: $appRouter.selectedTab) {
                bulletinBoardTab
                searchTab
                portalTab
                shopTab
                profileTab
            }
            .tint(Color.lightOrangeColor)
        }
        .onAppear {
            userManager.loadCurrentUser()
        }
        .onOpenURL { url in
            appRouter.handleDeepLink(url: url)
        }
    }

    // MARK: - Tab Views

    private var bulletinBoardTab: some View {
        NavigationStack(path: appRouter.pathBinding(for: .bulletinboard)) {
            BulletinBoardView()
                .navigationTitle("ホーム")
                .navigationDestination(for: RouterDestination.self) { destination in
                    DestinationViewBuilder.view(for: destination)
                }
        }
        .environment(bulletinBoardViewModel)
        .withTabEnvironment(userManager: userManager, sidebarState: sidebarState, appRouter: appRouter)
        .tabItem {
            Image(systemName: "house.fill")
            Text("ホーム")
        }
        .tag(TabSelection.bulletinboard)
    }

    private var searchTab: some View {
        NavigationStack(path: appRouter.pathBinding(for: .search)) {
            SearchView()
                .navigationTitle("検索")
                .navigationDestination(for: RouterDestination.self) { destination in
                    DestinationViewBuilder.view(for: destination)
                }
        }
        .withTabEnvironment(userManager: userManager, sidebarState: sidebarState, appRouter: appRouter)
        .tabItem {
            Image(systemName: "magnifyingglass")
            Text("検索")
        }
        .tag(TabSelection.search)
    }

    private var portalTab: some View {
        NavigationStack(path: appRouter.pathBinding(for: .portal)) {
            PortalView()
                .navigationDestination(for: RouterDestination.self) { destination in
                    DestinationViewBuilder.view(for: destination)
                }
        }
        .withTabEnvironment(userManager: userManager, sidebarState: sidebarState, appRouter: appRouter)
        .tabItem {
            Image(systemName: "rectangle.grid.2x2")
            Text("ポータル")
        }
        .tag(TabSelection.portal)
    }

    private var shopTab: some View {
        NavigationStack(path: appRouter.pathBinding(for: .shop)) {
            ShopTabView()
                .navigationTitle("お店")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: RouterDestination.self) { destination in
                    DestinationViewBuilder.view(for: destination)
                }
        }
        .withTabEnvironment(userManager: userManager, sidebarState: sidebarState, appRouter: appRouter)
        .tabItem {
            Image(systemName: "storefront.fill")
            Text("お店")
        }
        .tag(TabSelection.shop)
    }

    private var profileTab: some View {
        NavigationStack(path: appRouter.pathBinding(for: .profile)) {
            MyProfileView()
                .navigationTitle("プロフィール")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: RouterDestination.self) { destination in
                    DestinationViewBuilder.view(for: destination)
                }
        }
        .withTabEnvironment(userManager: userManager, sidebarState: sidebarState, appRouter: appRouter)
        .tabItem {
            Image(systemName: "person.crop.circle.fill")
            Text("プロフィール")
        }
        .tag(TabSelection.profile)
    }
}
