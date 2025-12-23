import SwiftUI

// MARK: - TabEnvironmentModifier

/// タブ共通の環境設定を適用する ViewModifier
///
/// 各タブで重複する環境設定を一元化し、DRY原則を遵守する。
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
    /// タブ共通の環境設定を適用
    /// - Parameters:
    ///   - userManager: ユーザー管理
    ///   - sidebarState: サイドバー状態
    ///   - appRouter: ナビゲーションルーター
    /// - Returns: 環境設定が適用された View
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
