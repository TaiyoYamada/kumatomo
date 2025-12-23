import SwiftUI

// MARK: - AnimatedEngagementIcon

/// ボタンアイコン自体のアニメーションを管理
struct AnimatedEngagementIcon: View {
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
    
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isActive ? activeColor : inactiveColor)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(y: yOffset)
            .onChange(of: isActive) { oldValue, newValue in
                if !oldValue && newValue {
                    playActivationAnimation()
                }
            }
    }
    
    private func playActivationAnimation() {
        switch animationType {
        case .like:
            playLikeAnimation()
        case .bookmark:
            playBookmarkAnimation()
        case .none:
            playSimpleBounce()
        }
    }
    
    private func playLikeAnimation() {
        // ドキドキアニメーション
        let sequence: [(scale: CGFloat, duration: Double)] = [
            (1.4, 0.1),
            (0.9, 0.1),
            (1.2, 0.1),
            (0.95, 0.08),
            (1.1, 0.08),
            (1.0, 0.1)
        ]
        
        var totalDelay: Double = 0
        
        for step in sequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                withAnimation(.easeInOut(duration: step.duration)) {
                    scale = step.scale
                }
            }
            totalDelay += step.duration
        }
    }
    
    private func playBookmarkAnimation() {
        // 跳ねるアニメーション
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
            scale = 1.35
            yOffset = -8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                scale = 1.0
                yOffset = 0
            }
        }
        
        // 軽い揺れ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.08)) {
                rotation = 8
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeInOut(duration: 0.08)) {
                rotation = -5
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            withAnimation(.easeInOut(duration: 0.1)) {
                rotation = 0
            }
        }
    }
    
    private func playSimpleBounce() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            scale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }
}
