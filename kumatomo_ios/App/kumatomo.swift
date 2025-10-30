import SwiftUI
import Resolver

@main
struct kumatomoApp: App {
    @State private var authViewModel = AuthViewModel()
    
    @MainActor
    init() {
        // Register dependencies
        Resolver.registerAllServices()
        print("👉 現在のAPI_BASE_URL:", APIConfig.shared.baseURLString)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
                .environment(AppRouter.shared)
                .environment(NetworkMonitor.shared)
                .environment(LocationManager.shared)
                .environment(FavoritesManager.shared)
                .environment(ProfileErrorHandler.shared)
                .environment(\.font, .custom("HelveticaNeue-RoundedBold", size: 16))
        }
    }
}
