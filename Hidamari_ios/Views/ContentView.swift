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
    @State private var selection: Selection = .home
    @StateObject private var bulletinBoardViewModel = BulletinBoardViewModel()
    @StateObject private var userManager = CurrentUserManager.shared
    
    enum Selection{
        case home
        case search
        case post
        case profile
        
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NetworkStatusBanner()
            
            TabView(selection: $selection) {
            //  ホームタブ（掲示板機能を統合）
            HomeView()
                .environmentObject(bulletinBoardViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(Selection.home)

            //  検索タブ
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("検索")
                }
                .tag(Selection.search)
                
            //  投稿タブ
            PostView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("投稿")
                }
                .tag(Selection.post)

            //  プロフィールタブ
            MyProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("プロフィール")
                }
                .tag(Selection.profile)
            
            }
            .accentColor(.pink)
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

