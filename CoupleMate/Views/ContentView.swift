import SwiftUI
import Firebase

struct ContentView: View {
    @StateObject var viewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if viewModel.userSession != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @StateObject var viewModel = AuthViewModel()
    
    var body: some View {
        TabView {
            Text("ホーム画面")
                .tabItem {
                    Image(systemName: "house")
                    Text("ホーム")
                }
            
            Text("メッセージ画面")
                .tabItem {
                    Image(systemName: "message")
                    Text("メッセージ")
                }
            
            Text("カレンダー画面")
                .tabItem {
                    Image(systemName: "calendar")
                    Text("カレンダー")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("プロフィール")
                }
        }
        .accentColor(.pink)
    }
}
