import SwiftUI
import Observation

struct SidebarButtonToolbarModifier: ViewModifier {
    @Environment(\.openSidebar) private var openSidebar
    @Environment(CurrentUserManager.self) private var userManager
    @Environment(SidebarState.self) private var sidebarState
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
