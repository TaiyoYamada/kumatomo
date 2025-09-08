import SwiftUI

@main
struct kumatomoApp: App {
    @StateObject var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environment(\.font, .custom("HelveticaNeue-RoundedBold", size: 16))
        }
    }
}
