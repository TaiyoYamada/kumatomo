import SwiftUI

@main
struct DailyStoryApp: App {
    // 認証用のViewModelをアプリ全体に持たせる
    @StateObject var viewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
