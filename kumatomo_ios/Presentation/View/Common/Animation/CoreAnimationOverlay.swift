import SwiftUI

// MARK: - CoreAnimationOverlay

/// Core Animationを使用したアニメーション効果をオーバーレイとして表示
/// レイアウトに影響を与えないよう設計されている
struct CoreAnimationOverlay: View {
    let isActive: Bool
    let color: Color
    let animationType: AnimationType
    
    enum AnimationType {
        case like
        case bookmark
    }
    
    @State private var particles: [ParticleData] = []
    @State private var ringScale: CGFloat = 0
    @State private var ringOpacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // リングエフェクト
                Circle()
                    .stroke(color.opacity(ringOpacity), lineWidth: 2)
                    .scaleEffect(ringScale)
                    .frame(width: 20, height: 20)
                    .position(center)
                
                // パーティクル
                ForEach(particles) { particle in
                    ParticleView(
                        particle: particle,
                        center: center,
                        animationType: animationType
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { oldValue, newValue in
            if !oldValue && newValue {
                triggerAnimation()
            }
        }
    }
    
    private func triggerAnimation() {
        // リングアニメーション
        withAnimation(.easeOut(duration: 0.4)) {
            ringScale = 2.5
            ringOpacity = 0.6
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                ringOpacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ringScale = 0
        }
        
        // パーティクル生成
        particles = []
        let particleCount = animationType == .like ? 8 : 6
        
        for i in 0..<particleCount {
            let angle = (CGFloat(i) / CGFloat(particleCount)) * 2 * .pi - .pi / 2
            let delay = Double(i) * 0.02
            
            particles.append(ParticleData(
                id: UUID(),
                angle: angle,
                color: color,
                delay: delay,
                distance: CGFloat.random(in: 25...40)
            ))
        }
        
        // パーティクルをクリア
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            particles = []
        }
    }
}

// MARK: - ParticleData (fileprivate Helper)

/// パーティクルのデータモデル
fileprivate struct ParticleData: Identifiable {
    let id: UUID
    let angle: CGFloat
    let color: Color
    let delay: Double
    let distance: CGFloat
}

// MARK: - ParticleView (fileprivate Helper)

/// 個別のパーティクルビュー
fileprivate struct ParticleView: View {
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
