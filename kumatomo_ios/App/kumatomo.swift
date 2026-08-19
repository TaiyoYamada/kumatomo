import SwiftUI

@main
struct kumatomoApp: App {
    @State private var authViewModel = AuthViewModel()

    @MainActor
    init() {
        print("👉 現在のAPI_BASE_URL:", APIConfig.shared.baseURLString)

        // ナビゲーションバーの外観をオレンジ色に設定
        configureNavigationBarAppearance()
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
                    .system(size: 16, weight: .semibold, design: .rounded)
                )
        }
    }

    /// ナビゲーションバーの外観を設定
    private func configureNavigationBarAppearance() {

        let lightOrange = UIColor(red: 1.0, green: 0.541, blue: 0.396, alpha: 1.0)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = lightOrange

        // タイトルの色を白に設定
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        // 戻るボタンのテキストを非表示に
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = backButtonAppearance

        // すべてのナビゲーションバーに適用
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // ナビゲーションバーのアイテム（ボタン）の色を白に
        UINavigationBar.appearance().tintColor = .white
    }
}
