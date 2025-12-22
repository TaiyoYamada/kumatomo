import SwiftUI

// MARK: - SidebarControlKey

struct SidebarControlKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var openSidebar: () -> Void {
        get { self[SidebarControlKey.self] }
        set { self[SidebarControlKey.self] = newValue }
    }
}
