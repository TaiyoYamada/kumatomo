import SwiftUI

// MARK: - ParticleView

/// 個別のパーティクルビュー
struct ParticleView: View {
    let particle: ParticleData
    let center: CGPoint
    let animationType: CoreAnimationOverlay.AnimationType
    
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        Group {
            if animationType == .like {
                // ハートパーティクル
                Image(systemName: "heart.fill")
                    .font(.system(size: 8))
                    .foregroundColor(particle.color)
            } else {
                // 星パーティクル
                Image(systemName: "star.fill")
                    .font(.system(size: 7))
                    .foregroundColor(particle.color)
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .rotationEffect(.degrees(rotation))
        .offset(offset)
        .position(center)
        .onAppear {
            // 遅延してアニメーション開始
            DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
                // 外側へ飛んでいく
                withAnimation(.easeOut(duration: 0.5)) {
                    offset = CGSize(
                        width: cos(particle.angle) * particle.distance,
                        height: sin(particle.angle) * particle.distance
                    )
                    scale = 1.2
                    opacity = 1
                    rotation = Double.random(in: -45...45)
                }
                
                // フェードアウト
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        opacity = 0
                        scale = 0.5
                    }
                }
            }
        }
    }
}
