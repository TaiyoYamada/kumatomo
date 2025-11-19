import SwiftUI

import Observation

struct ContentView: View {
    @State private var viewModel = AuthViewModel()
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
            } else if viewModel.isAuthenticated {
                if let done = viewModel.hasCompletedSetup {
                    if done {
                        MainTabView()
                    } else {
                        InitialSetupView()
                            .environment(viewModel)
                    }
                } else {
                    // 認証済みだがユーザー情報のロードが未完了。フリッカー防止の待機画面。
                    LaunchScreenView()
                }
            } else {
                LoginView()
                    .environment(viewModel)
            }
        }
        .environment(viewModel)
    }
}
