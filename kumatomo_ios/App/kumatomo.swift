import SwiftUI

@main
struct kumatomoApp: App {
    @State private var authViewModel = AuthViewModel()

    @MainActor
    init() {

        print("👉 現在のAPI_BASE_URL:", APIConfig.shared.baseURLString)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
                .environment(AppRouter.shared)
                .environment(NetworkMonitor.shared)
                .environment(LocationManager.shared)
                .environment(ProfileErrorHandler.shared)
                .environment(
                    \.font,
                    .system(size: 16, weight: .bold, design: .rounded)
                )
        }
    }
}
