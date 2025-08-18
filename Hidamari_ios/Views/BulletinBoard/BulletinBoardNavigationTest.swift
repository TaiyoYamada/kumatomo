import SwiftUI

// Test view to verify navigation integration
struct BulletinBoardNavigationTest: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Text("Home Tab")
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)
            
            BulletinBoardScreen()
                .environmentObject(BulletinBoardViewModel())
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("掲示板")
                }
                .tag(1)
            
            Text("Other Tab")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("検索")
                }
                .tag(2)
        }
        .onAppear {
            // Test navigation to bulletin board
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                selectedTab = 1
            }
        }
    }
}
