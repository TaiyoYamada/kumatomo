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
                    Text("ホーム")
                }
            
            //  プラン探しタブ
            Text("プラン探し画面")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("プラン探し")
                }
            
            
            // 投稿タブ
            Text("投稿画面")
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }

            
            //  思い出タブ
            Text("特に何もない画面")
//            MemoriesView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("思い出")
                }
            
            //  プロフィールタブ
            MyPageView()
//            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("プロフィール")
                }
        }
        .accentColor(.pink)
    }
}
