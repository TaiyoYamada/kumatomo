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
            } else if viewModel.isAuthenticated {
                if viewModel.hasCompletedSetup {
                    MainTabView(viewModel: viewModel)
                } else {
                    InitialSetupView()
                        .environmentObject(viewModel)
                }
            } else {
                LoginView()
                    .environmentObject(viewModel)
            }
        }
    }
}
