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
    @State private var showingPostView = false
    @State private var selection: Selection = .home
    
    enum Selection{
        case home
        case search
        case post
        case notification
        case profile
        
    }
    
    var body: some View {
        TabView(selection: $selection) {
            //  ホームタブ
            Text("ホーム画面")
                .tabItem {
                    Image(systemName: "house.fill")
                }
                .tag(Selection.home)

            //  プラン探しタブ
            Text("プラン探し画面")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
                .tag(Selection.search)

            //  投稿タブ
            Text("投稿画面")
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                }
                .tag(Selection.post)
            
            //  思い出タブ
            Text("お知らせ画面")
                .tabItem {
                    Image(systemName: "bell.fill")
                }
                .tag(Selection.notification)

            
            //  プロフィールタブ
            MyPageView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                }
                .tag(Selection.profile)
            
        }
        .accentColor(.pink)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
