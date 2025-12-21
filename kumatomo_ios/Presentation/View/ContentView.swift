import SwiftUI

struct ContentView: View {
    // kumatomoApp から Environment 経由で受け取る（重複インスタンス作成を防止）
    @Environment(AuthViewModel.self) private var viewModel
    @State private var isSplashFinished = false

    var body: some View {
        Group {
            if !isSplashFinished {
                LaunchScreenView()
                    .task {
                        try? await Task.sleep(for: .seconds(1.5))
                        withAnimation {
                            isSplashFinished = true
                        }
                    }
            } else if viewModel.isAuthenticated {
                if let done = viewModel.hasCompletedSetup, done {
                    MainTabView()
                } else if viewModel.hasCompletedSetup == nil {
                    // 認証済みだがユーザー情報のロードが未完了。フリッカー防止の待機画面。
                    LaunchScreenView()
                } else {
                    InitialSetupView()
                }
            } else {
                LoginView()
            }
        }
    }
}
