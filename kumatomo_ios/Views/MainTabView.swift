import SwiftUI
import UIKit

struct MainTabView: View {
    @ObservedObject var viewModel: AuthViewModel
    @StateObject private var bulletinBoardViewModel = BulletinBoardViewModel()
    @StateObject private var userManager = CurrentUserManager.shared
    @StateObject private var sidebarState = SidebarState()
    @StateObject private var appRouter = AppRouter.shared

    var body: some View {
        SidebarContainer(isPresented: $sidebarState.isPresented, user: userManager.currentUser) {
            MainTabBarControllerRepresentable(
                appRouter: appRouter,
                bulletinBoardViewModel: bulletinBoardViewModel,
                userManager: userManager,
                sidebarState: sidebarState
            )
            .ignoresSafeArea(.keyboard) // キーボード表示時にタブバーが隠れないように
        }
        .errorOverlay()
        .onAppear {
            userManager.loadCurrentUser()
        }
        .onOpenURL { url in
            appRouter.handleDeepLink(url: url)
        }
    }
}

// MARK: - UIViewControllerRepresentable for UITabBarController
private struct MainTabBarControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var appRouter: AppRouter
    @ObservedObject var bulletinBoardViewModel: BulletinBoardViewModel
    @ObservedObject var userManager: CurrentUserManager
    @ObservedObject var sidebarState: SidebarState

    func makeUIViewController(context: Context) -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.delegate = context.coordinator
        
        // 各タブに表示するSwiftUIビューをUIHostingControllerでラップ
        let homeView = HomeView()
            .environmentObject(bulletinBoardViewModel)
            .environmentObject(userManager)
            .environmentObject(sidebarState)
            .environment(\.openSidebar, sidebarState.open)
            .withAppRouter()
        
        let searchView = SearchView()
            .environmentObject(userManager)
            .environmentObject(sidebarState)
            .environment(\.openSidebar, sidebarState.open)
            .withAppRouter()

        let portalView = PortalView()
            .environmentObject(userManager)
            .environmentObject(sidebarState)
            .environment(\.openSidebar, sidebarState.open)
            .withAppRouter()
            
        let kumamonAIView = KumamonAIView()
            .environmentObject(userManager)
            .environmentObject(sidebarState)
            .environment(\.openSidebar, sidebarState.open)

        let myProfileView = MyProfileView()
            .environmentObject(userManager)
            .environmentObject(sidebarState)
            .environment(\.openSidebar, sidebarState.open)

        // 各タブのViewControllerを設定
        let homeVC = UIHostingController(rootView: NavigationStack(path: appRouter.pathBinding(for: .home)) { homeView.navigationTitle("ホーム") })
        let searchVC = UIHostingController(rootView: NavigationStack(path: appRouter.pathBinding(for: .search)) { searchView.navigationTitle("検索") })
        let portalVC = UIHostingController(rootView: NavigationStack(path: appRouter.pathBinding(for: .portal)) { portalView })
        let kumamonVC = UIHostingController(rootView: kumamonAIView)
        let profileVC = UIHostingController(rootView: myProfileView)

        // タブバーアイテムの初期設定
        homeVC.tabBarItem = UITabBarItem(title: "ホーム", image: UIImage(systemName: "house.fill"), tag: 0)
        searchVC.tabBarItem = UITabBarItem(title: "検索", image: UIImage(systemName: "magnifyingglass"), tag: 1)
        portalVC.tabBarItem = UITabBarItem(title: "ポータル", image: UIImage(systemName: "rectangle.grid.2x2"), tag: 2)
        kumamonVC.tabBarItem = UITabBarItem(title: "くまモンAI", image: UIImage(systemName: "bubble.left.and.bubble.right"), tag: 3)
        profileVC.tabBarItem = UITabBarItem(title: "プロフィール", image: UIImage(systemName: "person.crop.circle.fill"), tag: 4)

        tabBarController.viewControllers = [homeVC, searchVC, portalVC, kumamonVC, profileVC]
        tabBarController.tabBar.tintColor = UIColor(Color.primaryOrange)
        
        return tabBarController
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        // SwiftUI側で選択タブが変更されたら、UITabBarControllerに反映
        let tag = context.coordinator.tag(for: appRouter.selectedTab)
        if uiViewController.selectedIndex != tag {
            uiViewController.selectedIndex = tag
        }

        // プロフィール画像のURLを監視し、変更があればアイコンを更新
        context.coordinator.updateProfileImageIfNeeded(
            for: uiViewController.viewControllers?[4].tabBarItem, // 5番目のタブ
            with: userManager.currentUser?.profileImageURL
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, UITabBarControllerDelegate {
        var parent: MainTabBarControllerRepresentable
        private var lastLoadedURL: String?

        init(parent: MainTabBarControllerRepresentable) {
            self.parent = parent
        }

        // UIKit側でタブが選択されたら、SwiftUI側に反映
        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            parent.appRouter.selectedTab = tabSelection(for: tabBarController.selectedIndex)
        }
        
        // プロフィール画像を非同期で読み込み、加工してアイコンに設定
        func updateProfileImageIfNeeded(for tabBarItem: UITabBarItem?, with urlString: String?) {
            guard let tabBarItem = tabBarItem, let urlString = urlString, !urlString.isEmpty else { return }
            
            // 最後に読み込んだURLと同じなら処理をスキップ
            if urlString == lastLoadedURL { return }
            lastLoadedURL = urlString
            
            Task {
                guard let url = URL(string: urlString),
                      let (data, _) = try? await URLSession.shared.data(from: url),
                      let downloadedImage = UIImage(data: data) else {
                    return
                }
                
                // 画像をリサイズし、円形にクリップ
                let iconSize = CGSize(width: 25, height: 25)
                let processedImage = await processImage(downloadedImage, for: iconSize)
                
                // メインスレッドでUIを更新
                await MainActor.run {
                    let finalImage = processedImage?.withRenderingMode(.alwaysOriginal)
                    tabBarItem.image = finalImage
                    tabBarItem.selectedImage = finalImage
                }
            }
        }

        // UIImageをリサイズ＆円形に加工するヘルパーメソッド
        private func processImage(_ image: UIImage, for size: CGSize) async -> UIImage? {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                let rect = CGRect(origin: .zero, size: size)
                UIBezierPath(ovalIn: rect).addClip()
                image.draw(in: rect)
            }
        }
        
        // TabSelectionとInt(tag)を相互変換するヘルパー
        func tag(for selection: TabSelection) -> Int {
            switch selection {
            case .home: return 0
            case .search: return 1
            case .portal: return 2
            case .kumamonAI: return 3
            case .profile: return 4
            }
        }

        func tabSelection(for tag: Int) -> TabSelection {
            switch tag {
            case 0: return .home
            case 1: return .search
            case 2: return .portal
            case 3: return .kumamonAI
            case 4: return .profile
            default: return .portal
            }
        }
    }
}
