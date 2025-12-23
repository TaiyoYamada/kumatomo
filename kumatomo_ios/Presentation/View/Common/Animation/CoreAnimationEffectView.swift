import SwiftUI
import UIKit
import QuartzCore

// MARK: - CoreAnimationEffectView

/// Core Animation（CALayer, CAEmitterLayer）を使用したパーティクルエフェクト
/// SwiftUIからUIViewRepresentableでブリッジして使用する
struct CoreAnimationEffectView: UIViewRepresentable {
    let isActive: Bool
    let color: UIColor
    let effectType: EffectType

    enum EffectType {
        case like
        case bookmark
    }

    func makeUIView(context: Context) -> EffectContainerView {
        EffectContainerView()
    }

    func updateUIView(_ uiView: EffectContainerView, context: Context) {
        if isActive {
            switch effectType {
            case .like:
                uiView.playLikeEffect(color: color)
            case .bookmark:
                uiView.playBookmarkEffect(color: color)
            }
        }
    }
}

// MARK: - EffectContainerView

/// Core Animationエフェクトを管理するUIView
final class EffectContainerView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        clipsToBounds = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - いいねエフェクト（ハートが弾ける）

    func playLikeEffect(color: UIColor) {
        // エミッターレイヤーでハートパーティクル
        let emitter = createHeartEmitter(color: color)
        layer.addSublayer(emitter)

        // リングエフェクト
        addRingEffect(color: color)

        // エミッターを停止してクリーンアップ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitter.birthRate = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            emitter.removeFromSuperlayer()
        }
    }

    private func createHeartEmitter(color: UIColor) -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize = CGSize(width: 1, height: 1)
        emitter.emitterShape = .point
        emitter.renderMode = .additive

        // ハートセル
        let heartCell = CAEmitterCell()
        heartCell.contents = createHeartImage(color: color)?.cgImage
        heartCell.birthRate = 20
        heartCell.lifetime = 0.5
        heartCell.velocity = 60
        heartCell.velocityRange = 20
        heartCell.emissionRange = .pi * 2
        heartCell.scale = 0.08
        heartCell.scaleRange = 0.02
        heartCell.scaleSpeed = -0.1
        heartCell.alphaSpeed = -1.2
        heartCell.spin = 0
        heartCell.spinRange = .pi

        emitter.emitterCells = [heartCell]
        return emitter
    }

    private func createHeartImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 30, height: 30)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)

            // ハートのパス
            let path = UIBezierPath()
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let heartWidth = size.width * 0.8
            let heartHeight = size.height * 0.8

            path.move(to: CGPoint(x: center.x, y: center.y + heartHeight * 0.35))

            // 左側の曲線
            path.addCurve(
                to: CGPoint(x: center.x - heartWidth * 0.5, y: center.y - heartHeight * 0.1),
                controlPoint1: CGPoint(x: center.x - heartWidth * 0.2, y: center.y + heartHeight * 0.2),
                controlPoint2: CGPoint(x: center.x - heartWidth * 0.5, y: center.y + heartHeight * 0.1)
            )

            path.addCurve(
                to: CGPoint(x: center.x, y: center.y - heartHeight * 0.35),
                controlPoint1: CGPoint(x: center.x - heartWidth * 0.5, y: center.y - heartHeight * 0.35),
                controlPoint2: CGPoint(x: center.x - heartWidth * 0.1, y: center.y - heartHeight * 0.35)
            )

            // 右側の曲線
            path.addCurve(
                to: CGPoint(x: center.x + heartWidth * 0.5, y: center.y - heartHeight * 0.1),
                controlPoint1: CGPoint(x: center.x + heartWidth * 0.1, y: center.y - heartHeight * 0.35),
                controlPoint2: CGPoint(x: center.x + heartWidth * 0.5, y: center.y - heartHeight * 0.35)
            )

            path.addCurve(
                to: CGPoint(x: center.x, y: center.y + heartHeight * 0.35),
                controlPoint1: CGPoint(x: center.x + heartWidth * 0.5, y: center.y + heartHeight * 0.1),
                controlPoint2: CGPoint(x: center.x + heartWidth * 0.2, y: center.y + heartHeight * 0.2)
            )

            path.close()

            color.setFill()
            path.fill()
        }
    }

    private func addRingEffect(color: UIColor) {
        let ringLayer = CAShapeLayer()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        ringLayer.path = UIBezierPath(
            arcCenter: center,
            radius: 8,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.strokeColor = color.withAlphaComponent(0.8).cgColor
        ringLayer.lineWidth = 3
        ringLayer.opacity = 0
        layer.addSublayer(ringLayer)

        // スケールアニメーション
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 2.0

        // 透明度アニメーション
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [0.8, 0.4, 0]
        opacityAnimation.keyTimes = [0, 0.5, 1]

        // 線幅アニメーション
        let lineWidthAnimation = CABasicAnimation(keyPath: "lineWidth")
        lineWidthAnimation.fromValue = 3
        lineWidthAnimation.toValue = 1

        let group = CAAnimationGroup()
        group.animations = [scaleAnimation, opacityAnimation, lineWidthAnimation]
        group.duration = 0.5
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak ringLayer] in
            ringLayer?.removeFromSuperlayer()
        }
        ringLayer.add(group, forKey: "ringExpand")
        CATransaction.commit()
    }

    // MARK: - ブックマークエフェクト（星が舞う）

    func playBookmarkEffect(color: UIColor) {
        // エミッターレイヤーで星パーティクル
        let emitter = createStarEmitter(color: color)
        layer.addSublayer(emitter)

        // スパークルライン
        addSparkleLines(color: color)

        // エミッターを停止してクリーンアップ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitter.birthRate = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            emitter.removeFromSuperlayer()
        }
    }

    private func createStarEmitter(color: UIColor) -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize = CGSize(width: 1, height: 1)
        emitter.emitterShape = .point
        emitter.renderMode = .additive

        // 星セル
        let starCell = CAEmitterCell()
        starCell.contents = createStarImage(color: color)?.cgImage
        starCell.birthRate = 18
        starCell.lifetime = 0.5
        starCell.velocity = 50
        starCell.velocityRange = 15
        starCell.emissionRange = .pi * 2
        starCell.scale = 0.06
        starCell.scaleRange = 0.02
        starCell.scaleSpeed = -0.08
        starCell.alphaSpeed = -1.4
        starCell.spin = 2
        starCell.spinRange = 4

        emitter.emitterCells = [starCell]
        return emitter
    }

    private func createStarImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 30, height: 30)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerRadius: CGFloat = 12
            let innerRadius: CGFloat = 5
            let points = 5

            let path = UIBezierPath()
            var angle: CGFloat = -.pi / 2
            let angleIncrement = .pi / CGFloat(points)

            path.move(to: CGPoint(
                x: center.x + outerRadius * cos(angle),
                y: center.y + outerRadius * sin(angle)
            ))

            for _ in 0 ..< points {
                angle += angleIncrement
                path.addLine(to: CGPoint(
                    x: center.x + innerRadius * cos(angle),
                    y: center.y + innerRadius * sin(angle)
                ))

                angle += angleIncrement
                path.addLine(to: CGPoint(
                    x: center.x + outerRadius * cos(angle),
                    y: center.y + outerRadius * sin(angle)
                ))
            }

            path.close()

            color.setFill()
            path.fill()
        }
    }

    private func addSparkleLines(color: UIColor) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let lineCount = 6

        for i in 0 ..< lineCount {
            let angle = (CGFloat(i) / CGFloat(lineCount)) * .pi * 2

            let lineLayer = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: center)
            path.addLine(to: CGPoint(
                x: center.x + cos(angle) * 12,
                y: center.y + sin(angle) * 12
            ))

            lineLayer.path = path.cgPath
            lineLayer.strokeColor = color.withAlphaComponent(0.9).cgColor
            lineLayer.lineWidth = 2
            lineLayer.lineCap = .round
            lineLayer.opacity = 0
            layer.addSublayer(lineLayer)

            // ストロークアニメーション
            let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeEndAnimation.fromValue = 0
            strokeEndAnimation.toValue = 1
            strokeEndAnimation.duration = 0.2

            let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
            strokeStartAnimation.fromValue = 0
            strokeStartAnimation.toValue = 1
            strokeStartAnimation.duration = 0.2
            strokeStartAnimation.beginTime = 0.15

            let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
            opacityAnimation.values = [0, 1, 1, 0]
            opacityAnimation.keyTimes = [0, 0.1, 0.6, 1]

            let group = CAAnimationGroup()
            group.animations = [strokeEndAnimation, strokeStartAnimation, opacityAnimation]
            group.duration = 0.4
            group.beginTime = CACurrentMediaTime() + Double(i) * 0.03
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)

            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak lineLayer] in
                lineLayer?.removeFromSuperlayer()
            }
            lineLayer.add(group, forKey: "sparkle")
            CATransaction.commit()
        }
    }
}
