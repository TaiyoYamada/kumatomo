import SwiftUI
import UIKit

// MARK: - ZoomableImageView

/// UIScrollViewを使用したピンチズーム対応画像ビュー
/// Core Animation (UIScrollView.zoomScale) を活用してTwitter並の滑らかなズームを実現
struct ZoomableImageView: UIViewRepresentable {
    let imageURL: URL?
    let image: UIImage?

    init(imageURL: URL?) {
        self.imageURL = imageURL
        image = nil
    }

    init(image: UIImage) {
        imageURL = nil
        self.image = image
    }

    func makeUIView(context: Context) -> ZoomableScrollView {
        let scrollView = ZoomableScrollView()
        scrollView.delegate = context.coordinator
        return scrollView
    }

    func updateUIView(_ scrollView: ZoomableScrollView, context: Context) {
        if let image {
            scrollView.setImage(image)
        } else if let imageURL {
            scrollView.loadImage(from: imageURL)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return (scrollView as? ZoomableScrollView)?.imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let zoomableScrollView = scrollView as? ZoomableScrollView else { return }
            zoomableScrollView.centerImage()
        }
    }
}

// MARK: - ZoomableScrollView

/// ズーム対応UIScrollView
final class ZoomableScrollView: UIScrollView {

    let imageView = UIImageView()
    private var imageLoadTask: URLSessionTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()
        setupImageView()
        setupGestures()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupScrollView() {
        minimumZoomScale = 1.0
        maximumZoomScale = 3.0
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        backgroundColor = .clear
        bouncesZoom = true

        // スプリングアニメーション付きズーム
        decelerationRate = .fast
    }

    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        addSubview(imageView)
    }

    private func setupGestures() {
        // ダブルタップでズームトグル
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if zoomScale > minimumZoomScale {
            // ズームアウト（スプリングアニメーション）
            animateZoom(to: minimumZoomScale)
        } else {
            // タップ位置を中心にズームイン
            let location = gesture.location(in: imageView)
            let zoomRect = zoomRectForScale(maximumZoomScale * 0.7, center: location)
            animateZoom(to: zoomRect)
        }
    }

    private func animateZoom(to scale: CGFloat) {
        // CASpringAnimation相当のバウンス効果
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: [.curveEaseOut]
        ) {
            self.setZoomScale(scale, animated: false)
        }
    }

    private func animateZoom(to rect: CGRect) {
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: [.curveEaseOut]
        ) {
            self.zoom(to: rect, animated: false)
        }
    }

    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        let width = bounds.width / scale
        let height = bounds.height / scale
        let x = center.x - (width / 2)
        let y = center.y - (height / 2)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    // MARK: - Image Loading

    // 内部キャッシュ (既存のImageCacheとの重複を避ける)
    private static let imageCache = NSCache<NSURL, UIImage>()

    func setImage(_ image: UIImage) {
        imageLoadTask?.cancel()
        imageView.image = image
        layoutImageView()
    }

    func loadImage(from url: URL) {
        imageLoadTask?.cancel()

        // キャッシュチェック
        if let cachedImage = Self.imageCache.object(forKey: url as NSURL) {
            setImage(cachedImage)
            return
        }

        imageLoadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self, let data, error == nil,
                  let image = UIImage(data: data) else { return }

            // キャッシュに保存
            Self.imageCache.setObject(image, forKey: url as NSURL)

            DispatchQueue.main.async {
                self.setImage(image)
            }
        }
        imageLoadTask?.resume()
    }

    private func layoutImageView() {
        guard let image = imageView.image else { return }

        let imageSize = image.size
        let boundsSize = bounds.size

        // アスペクト比を維持してフィット
        let widthRatio = boundsSize.width / imageSize.width
        let heightRatio = boundsSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio)

        let scaledSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        imageView.frame = CGRect(origin: .zero, size: scaledSize)
        contentSize = scaledSize

        centerImage()
        setZoomScale(minimumZoomScale, animated: false)
    }

    func centerImage() {
        let offsetX = max((bounds.width - contentSize.width) / 2, 0)
        let offsetY = max((bounds.height - contentSize.height) / 2, 0)
        imageView.center = CGPoint(
            x: contentSize.width / 2 + offsetX,
            y: contentSize.height / 2 + offsetY
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if imageView.image != nil, imageView.frame.size == .zero {
            layoutImageView()
        }
    }
}
