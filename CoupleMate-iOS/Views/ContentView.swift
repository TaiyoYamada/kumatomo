import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                MainTabView(viewModel: viewModel)
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        TabView {
            //  ホームタブ
            Text("ホーム画面")
                .tabItem {
                    Image(systemName: "house.fill")
                }
            
            //  プラン探しタブ
            Text("プラン探し画面")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
            
            
            // 投稿タブ
//            Text("投稿画面")
            PostView()
                .tabItem {
                    Image(systemName: "plus.app")
                }

            
            //  思い出タブ
            Text("お知らせ画面")
                .tabItem {
                    Image(systemName: "speaker.square")
                }
            
            //  プロフィールタブ
            MyPageView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                }
        }
        .accentColor(.pink)
    }
}
