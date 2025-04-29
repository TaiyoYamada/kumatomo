import SwiftUI

@main
struct CoupleApp: App {
    // AppDelegateを登録
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // 認証用のViewModelをアプリ全体に持たせる
    @StateObject var viewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
