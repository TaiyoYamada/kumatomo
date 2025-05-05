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
            //  思い出タブ
            MemoriesView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("思い出")
                }
            
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
            
            //  プロフィールタブ
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("プロフィール")
                }
        }
        .accentColor(.pink)
    }
}
