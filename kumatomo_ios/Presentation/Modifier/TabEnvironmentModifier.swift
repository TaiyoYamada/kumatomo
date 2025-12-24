import SwiftUI

// MARK: - TabEnvironmentModifier

struct TabEnvironmentModifier: ViewModifier {
    let userManager: CurrentUserManager
    let sidebarState: SidebarState
    let appRouter: AppRouter

    func body(content: Content) -> some View {
        content
            .environment(userManager)
            .environment(sidebarState)
            .environment(appRouter)
            .environment(\.openSidebar, sidebarState.open)
    }
}

// MARK: - View Extension

extension View {
    func withTabEnvironment(
        userManager: CurrentUserManager,
        sidebarState: SidebarState,
        appRouter: AppRouter
    ) -> some View {
        modifier(TabEnvironmentModifier(
            userManager: userManager,
            sidebarState: sidebarState,
            appRouter: appRouter
        ))
    }
}
