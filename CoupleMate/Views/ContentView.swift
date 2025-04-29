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
            
            Text("思い出画面")
                .tabItem {
                    Image(systemName: "calendar")
                    Text("思い出")
                }
            
            Text("デート")
                .tabItem {
                    Image(systemName: "person.2")
                    Text("デート")
                }
            
            ProfileView(viewModel: ProfileViewModel())
                .tabItem {
                    Image(systemName: "person")
                    Text("プロフィール")
                }
        }
        .accentColor(.pink)
    }
}
