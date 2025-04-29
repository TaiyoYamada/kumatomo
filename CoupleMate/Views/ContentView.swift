import SwiftUI
import Firebase

struct ContentView: View {
    @StateObject var viewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if viewModel.userSession != nil {
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
            // 🏠 ホームタブ
            Text("ホーム画面")
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
            
            // 📖 思い出タブ
            MemoriesView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("思い出")
                }
            
            // 🔍 プラン探しタブ
            Text("プラン探し画面")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("プラン探し")
                }
            
            // 📅 カレンダータブ
            Text("カレンダー画面")
                .tabItem {
                    Image(systemName: "calendar")
                    Text("カレンダー")
                }
            
            // 👤 プロフィールタブ
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("プロフィール")
                }
        }
        .accentColor(.pink)
    }
}
