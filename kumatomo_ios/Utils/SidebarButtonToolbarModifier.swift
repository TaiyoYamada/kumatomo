import SwiftUI

struct SidebarButtonToolbarModifier: ViewModifier {
    @Environment(\.openSidebar) private var openSidebar
    @EnvironmentObject private var userManager: CurrentUserManager
    @EnvironmentObject private var sidebarState: SidebarState
    let show: Bool

    func body(content: Content) -> some View {
        content.toolbar {
            if show && !sidebarState.isPresented {
                ToolbarItem(placement: .navigationBarLeading) {
                    ProfileIconButton(user: userManager.currentUser) {
                        openSidebar()
                    }
                }
            }
        }
    }
}

extension View {
    func sidebarButton(show: Bool = true) -> some View {
        self.modifier(SidebarButtonToolbarModifier(show: show))
    }
}

