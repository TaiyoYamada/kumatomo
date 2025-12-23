import SwiftUI

// MARK: - ParticleData

/// パーティクルのデータモデル
struct ParticleData: Identifiable {
    let id: UUID
    let angle: CGFloat
    let color: Color
    let delay: Double
    let distance: CGFloat
}
