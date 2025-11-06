import SwiftUI

enum AppAppearance {
    struct Navigation: ViewModifier {
        func body(content: Content) -> some View {
            content
                .toolbarBackground(.visible, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    struct Sheet: ViewModifier {
        func body(content: Content) -> some View {
            content
                .presentationCornerRadius(0)
                .presentationDetents([.large])
        }
    }
}

extension View {
    func appNavigationStyle() -> some View {
        modifier(AppAppearance.Navigation())
    }

    func appSheetStyle() -> some View {
        modifier(AppAppearance.Sheet())
    }
}

