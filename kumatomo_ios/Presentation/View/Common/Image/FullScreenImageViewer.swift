import SwiftUI
import UIKit

// MARK: - FullScreenImageViewer

/// フルスクリーン画像ビューワー
/// Twitter風のスワイプ閉じ、ページング、ズーム対応
struct FullScreenImageViewer: View {
    let imageURLs: [String]
    let startIndex: Int
    let onDismiss: () -> Void

    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var backgroundOpacity: Double = 1.0
    @State private var imageScale: CGFloat = 1.0

    init(imageURLs: [String], startIndex: Int = 0, onDismiss: @escaping () -> Void) {
        self.imageURLs = imageURLs
        self.startIndex = startIndex
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // 背景（ブラー + 暗め）
                Color.black
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()

                // ページングビュー
                ImagePagerView(
                    imageURLs: imageURLs,
                    currentIndex: $currentIndex
                )
                .offset(dragOffset)
                .scaleEffect(imageScale)
                .gesture(dismissGesture)

                // オーバーレイUI
                VStack {
                    // ヘッダー
                    headerView

                    Spacer()

                    // ページインジケーター
                    if imageURLs.count > 1 {
                        pageIndicator
                    }
                }
            }
        }
        .statusBarHidden(true)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Spacer()

            Button(action: dismissWithAnimation) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        Text("\(currentIndex + 1) / \(imageURLs.count)")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(16)
            .padding(.bottom, 32)
    }

    // MARK: - Dismiss Gesture

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // 縦方向のドラッグのみ反応
                let verticalDrag = value.translation.height
                dragOffset = CGSize(width: 0, height: verticalDrag)

                // ドラッグ量に応じて背景透明度を調整
                let progress = min(abs(verticalDrag) / 300, 1)
                backgroundOpacity = 1 - (progress * 0.5)
                imageScale = 1 - (progress * 0.1)
            }
            .onEnded { value in
                let verticalDrag = value.translation.height
                let velocity = value.predictedEndTranslation.height

                // 閉じる条件: 100pt以上ドラッグ or 速度が速い
                if abs(verticalDrag) > 100 || abs(velocity) > 500 {
                    dismissWithAnimation()
                } else {
                    // 元に戻る（スプリングアニメーション）
                    resetPosition()
                }
            }
    }

    // MARK: - Animations

    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            backgroundOpacity = 0
            imageScale = 0.8
            dragOffset = CGSize(width: 0, height: 300)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }

    private func resetPosition() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            dragOffset = .zero
            backgroundOpacity = 1.0
            imageScale = 1.0
        }
    }
}

// MARK: - ImagePagerView

/// 複数画像のページングビュー
struct ImagePagerView: UIViewControllerRepresentable {
    let imageURLs: [String]
    @Binding var currentIndex: Int

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: 16]
        )
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator
        pageVC.view.backgroundColor = .clear

        // 初期ページを設定
        if let initialVC = context.coordinator.viewController(at: currentIndex) {
            pageVC.setViewControllers([initialVC], direction: .forward, animated: false)
        }

        return pageVC
    }

    func updateUIViewController(_ pageVC: UIPageViewController, context: Context) {
        // インデックスが外部から変更された場合に同期
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let parent: ImagePagerView
        private var viewControllers: [Int: ImageHostingController] = [:]

        init(_ parent: ImagePagerView) {
            self.parent = parent
        }

        func viewController(at index: Int) -> ImageHostingController? {
            guard index >= 0, index < parent.imageURLs.count else { return nil }

            if let cached = viewControllers[index] {
                return cached
            }

            let imageURL = parent.imageURLs[index]
            let vc = ImageHostingController(imageURL: imageURL, index: index)
            viewControllers[index] = vc
            return vc
        }

        // MARK: - UIPageViewControllerDataSource

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let hostingVC = viewController as? ImageHostingController else { return nil }
            return self.viewController(at: hostingVC.index - 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let hostingVC = viewController as? ImageHostingController else { return nil }
            return self.viewController(at: hostingVC.index + 1)
        }

        // MARK: - UIPageViewControllerDelegate

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let currentVC = pageViewController.viewControllers?.first as? ImageHostingController else { return }
            parent.currentIndex = currentVC.index
        }
    }
}

// MARK: - ImageHostingController

/// 個別画像を表示するViewController
final class ImageHostingController: UIHostingController<ZoomableImageView> {
    let index: Int

    init(imageURL: String, index: Int) {
        self.index = index
        let url = URL(string: imageURL)
        super.init(rootView: ZoomableImageView(imageURL: url))
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
