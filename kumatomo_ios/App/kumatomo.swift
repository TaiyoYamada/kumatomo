import SwiftUI
import Resolver

@main
struct kumatomoApp: App {
    @StateObject var authViewModel = AuthViewModel()
    
    @MainActor
    init() {
        // Register dependencies
        Resolver.registerAllServices()
        print("👉 現在のAPI_BASE_URL:", APIConfig.shared.baseURLString)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environment(\.font, .custom("HelveticaNeue-RoundedBold", size: 16))
        }
    }
}
