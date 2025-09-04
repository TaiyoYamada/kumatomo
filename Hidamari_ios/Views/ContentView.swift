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
    @State private var showingPostView = false
    @State private var selection: TabSelection = .portal
    @StateObject private var bulletinBoardViewModel = BulletinBoardViewModel()
    @StateObject private var userManager = CurrentUserManager.shared
    @StateObject private var sidebarState = SidebarState()
    
    // TabSelectionはAppRouter/RouterDestination.swiftに移動
    
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
                    
                //  投稿タブ
                PostView()
                    .environmentObject(userManager)
                    .environment(\.openSidebar, sidebarState.open)
                    .tabItem {
                        Image(systemName: "plus.circle.fill")
                        Text("投稿")
                    }
                    .tag(TabSelection.post)


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
                .accentColor(.pink)
            }
        }
        .errorOverlay()
        .onAppear {
            userManager.loadCurrentUser()
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

