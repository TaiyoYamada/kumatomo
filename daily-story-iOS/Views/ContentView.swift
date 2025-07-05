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
            } else {
                if viewModel.isAuthenticated {
                    MainTabView(viewModel: viewModel)
                } else {
                    LoginView()
                }
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
        case post
        case profile
        
    }
    
    var body: some View {
        TabView(selection: $selection) {
            //  ホームタブ
            FeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                }
                .tag(Selection.home)

            //  投稿タブ
            PostView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                }
                .tag(Selection.post)

            
            //  プロフィールタブ
            MyProfileView()
//            MyPageView()
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

