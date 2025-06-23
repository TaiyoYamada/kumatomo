import SwiftUI

struct TabBarHider: UIViewControllerRepresentable {
    var isHidden: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            viewController.tabBarController?.tabBar.isHidden = isHidden
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            uiViewController.tabBarController?.tabBar.isHidden = isHidden
        }
    }
}
