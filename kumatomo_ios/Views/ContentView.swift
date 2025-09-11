import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = AuthViewModel()
    @State private var isSplashFinished = false

    var body: some View {
        Group {
            if !isSplashFinished {
                LaunchScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                isSplashFinished = true
                            }
                        }
                    }
            } else if viewModel.isAuthenticated {
                if viewModel.hasCompletedSetup {
                    MainTabView(viewModel: viewModel)
                } else {
                    InitialSetupView()
                        .environmentObject(viewModel)
                }
            } else {
                LoginView()
                    .environmentObject(viewModel)
            }
        }
    }
}

struct MainTabView: View {
    
    @ObservedObject var viewModel: AuthViewModel
    @State private var selection: TabSelection = .portal
    @StateObject private var bulletinBoardViewModel = BulletinBoardViewModel()
    @StateObject private var userManager = CurrentUserManager.shared
    @StateObject private var sidebarState = SidebarState()
    
    
    var body: some View {
        SidebarContainer(isPresented: $sidebarState.isPresented, user: userManager.currentUser) {
            VStack(spacing: 0) {
                NetworkStatusBanner()
                
                TabView(selection: $selection) {
                    //  ホームタブ（掲示板機能を統合）
                    HomeView()
                        .environmentObject(bulletinBoardViewModel)
                        .environmentObject(userManager)
                        .environment(\.openSidebar, sidebarState.open)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("ホーム")
                        }
                        .tag(TabSelection.home)
                    
                    //  検索タブ
                    SearchView()
                        .environmentObject(userManager)
                        .environment(\.openSidebar, sidebarState.open)
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("検索")
                        }
                        .tag(TabSelection.search)
                    
                    
                    //  ポータルタブ
                    PortalView()
                        .environmentObject(userManager)
                        .environment(\.openSidebar, sidebarState.open)
                        .tabItem {
                            Image(systemName: "rectangle.grid.2x2")
                            Text("ポータル")
                        }
                        .tag(TabSelection.portal)
                    
                    //  くまモンAIタブ
                    KumamonAIView()
                        .environmentObject(userManager)
                        .environment(\.openSidebar, sidebarState.open)
                        .tabItem {
                            Image(systemName: "bubble.left.and.bubble.right")
                            Text("くまモンAI")
                        }
                        .tag(TabSelection.kumamonAI)
                    
                    //  プロフィールタブ
                    MyProfileView()
                        .environmentObject(userManager)
                        .environment(\.openSidebar, sidebarState.open)
                        .tabItem {
                            Image(systemName: "person.crop.circle")
                            Text("プロフィール")
                        }
                        .tag(TabSelection.profile)
                    
                }
                .accentColor(Color.primaryOrange)
            }
        }
        .errorOverlay()
        .onAppear {
            userManager.loadCurrentUser()
        }
    }
}
