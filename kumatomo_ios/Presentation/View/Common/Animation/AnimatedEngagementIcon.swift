import SwiftUI
import UIKit
import QuartzCore

// MARK: - AnimatedEngagementIcon

/// Core Animationを使用したエンゲージメントボタンアイコン
/// CABasicAnimation, CAKeyframeAnimation, CASpringAnimationを使用
struct AnimatedEngagementIcon: UIViewRepresentable {
    let icon: String
    let isActive: Bool
    let activeColor: Color
    let inactiveColor: Color
    let animationType: AnimationType

    enum AnimationType {
        case like
        case bookmark
        case none
    }

    func makeUIView(context: Context) -> IconAnimationView {
        let view = IconAnimationView()
        view.configure(
            icon: icon,
            isActive: isActive,
            activeColor: UIColor(activeColor),
            inactiveColor: UIColor(inactiveColor)
        )
        return view
    }

    func updateUIView(_ uiView: IconAnimationView, context: Context) {
        let wasActive = uiView.currentIsActive

        uiView.configure(
            icon: icon,
            isActive: isActive,
            activeColor: UIColor(activeColor),
            inactiveColor: UIColor(inactiveColor)
        )

        // アクティブになった瞬間にアニメーション発火
        if !wasActive, isActive {
            switch animationType {
            case .like:
                uiView.playHeartbeatAnimation()
            case .bookmark:
                uiView.playBounceAnimation()
            case .none:
                uiView.playSimplePulse()
            }
        }
    }
}

// MARK: - IconAnimationView

/// Core Animationでアイコンをアニメーションさせるカスタムビュー
final class IconAnimationView: UIView {

    private let imageView = UIImageView()
    private(set) var currentIsActive = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(icon: String, isActive: Bool, activeColor: UIColor, inactiveColor: UIColor) {
        currentIsActive = isActive

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: icon, withConfiguration: config)
        imageView.image = image
        imageView.tintColor = isActive ? activeColor : inactiveColor
    }

    // MARK: - ドキドキアニメーション (Like)

    func playHeartbeatAnimation() {
        // 既存のアニメーションを削除
        imageView.layer.removeAllAnimations()

        // ドキドキスケールアニメーション (CAKeyframeAnimation)
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1.0, 1.5, 0.9, 1.25, 0.95, 1.1, 1.0]
        scaleAnimation.keyTimes = [0, 0.15, 0.3, 0.45, 0.6, 0.75, 1.0]
        scaleAnimation.duration = 0.6
        scaleAnimation.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeIn),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeIn),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]

        // 回転の揺れ
        let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.values = [0, -0.1, 0.1, -0.05, 0]
        rotationAnimation.keyTimes = [0, 0.25, 0.5, 0.75, 1.0]
        rotationAnimation.duration = 0.6

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, rotationAnimation]
        animationGroup.duration = 0.6
        animationGroup.isRemovedOnCompletion = true

        imageView.layer.add(animationGroup, forKey: "heartbeat")

        // 触覚フィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    // MARK: - バウンスアニメーション (Bookmark)

    func playBounceAnimation() {
        imageView.layer.removeAllAnimations()

        // Y軸の跳ねアニメーション
        let positionAnimation = CAKeyframeAnimation(keyPath: "position.y")
        let originalY = imageView.layer.position.y
        positionAnimation.values = [originalY, originalY - 12, originalY + 3, originalY - 5, originalY]
        positionAnimation.keyTimes = [0, 0.25, 0.5, 0.7, 1.0]
        positionAnimation.duration = 0.5
        positionAnimation.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeIn),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]

        // スケールのスクイッシュ＆ストレッチ
        let scaleXAnimation = CAKeyframeAnimation(keyPath: "transform.scale.x")
        scaleXAnimation.values = [1.0, 0.85, 1.15, 0.95, 1.0]
        scaleXAnimation.keyTimes = [0, 0.25, 0.5, 0.7, 1.0]
        scaleXAnimation.duration = 0.5

        let scaleYAnimation = CAKeyframeAnimation(keyPath: "transform.scale.y")
        scaleYAnimation.values = [1.0, 1.2, 0.9, 1.05, 1.0]
        scaleYAnimation.keyTimes = [0, 0.25, 0.5, 0.7, 1.0]
        scaleYAnimation.duration = 0.5

        // 回転の揺れ
        let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.values = [0, 0.15, -0.1, 0.05, 0]
        rotationAnimation.keyTimes = [0, 0.3, 0.55, 0.8, 1.0]
        rotationAnimation.duration = 0.5

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [positionAnimation, scaleXAnimation, scaleYAnimation, rotationAnimation]
        animationGroup.duration = 0.5
        animationGroup.isRemovedOnCompletion = true

        imageView.layer.add(animationGroup, forKey: "bounce")

        // 触覚フィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    // MARK: - シンプルパルス

    func playSimplePulse() {
        imageView.layer.removeAllAnimations()

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.2
        scaleAnimation.duration = 0.15
        scaleAnimation.autoreverses = true
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        imageView.layer.add(scaleAnimation, forKey: "pulse")
    }
}
