import SwiftUI

// MARK: - EngagementButton

struct EngagementButton: View {
    let icon: String
    let count: Int
    let isActive: Bool
    let activeColor: Color
    let animationType: AnimationType
    let action: () async -> Void

    @State private var showParticles = false

    enum AnimationType {
        case like
        case bookmark
        case comment
        case none
    }

    init(
        icon: String,
        count: Int,
        isActive: Bool = false,
        activeColor: Color = .primaryOrange,
        animationType: AnimationType = .none,
        action: @escaping () async -> Void
    ) {
        self.icon = icon
        self.count = count
        self.isActive = isActive
        self.activeColor = activeColor
        self.animationType = animationType
        self.action = action
    }

    var body: some View {
        Button {
            Task {
                await performAction()
            }
        } label: {
            HStack(spacing: 4) {
                AnimatedEngagementIcon(
                    icon: icon,
                    isActive: isActive,
                    activeColor: activeColor,
                    inactiveColor: Color.primary.opacity(0.6),
                    animationType: iconAnimationType
                )
                .frame(width: 24, height: 24)
                .overlay {
                    // Core Animation パーティクルオーバーレイ（レイアウトに影響しない）
                    if animationType == .like || animationType == .bookmark {
                        CoreAnimationEffectView(
                            isActive: showParticles,
                            color: UIColor(activeColor),
                            effectType: animationType == .like ? .like : .bookmark
                        )
                        .frame(width: 60, height: 60)
                        .allowsHitTesting(false)
                    }
                }

                if count > 0 {
                    Text(count.formatCount())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: count)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(PressEffectButtonStyle())
        .onChange(of: isActive) { oldValue, newValue in
            // アクティブになった時（false -> true）のみパーティクル発動
            if !oldValue, newValue {
                triggerParticleAnimation()
            }
        }
    }

    private var iconAnimationType: AnimatedEngagementIcon.AnimationType {
        switch animationType {
        case .like: return .like
        case .bookmark: return .bookmark
        case .comment, .none: return .none
        }
    }

    private func performAction() async {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        await action()
    }

    private func triggerParticleAnimation() {
        showParticles = true

        // アニメーション完了後にリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showParticles = false
        }
    }

    private var textColor: Color {
        if isActive {
            return activeColor
        } else {
            return Color.primary.opacity(0.7)
        }
    }
}

// MARK: - PressEffectButtonStyle

struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

extension EngagementButton {
    static func like(
        count: Int,
        isLiked: Bool,
        action: @escaping () async -> Void
    ) -> EngagementButton {
        EngagementButton(
            icon: isLiked ? "heart.fill" : "heart",
            count: count,
            isActive: isLiked,
            activeColor: .red,
            animationType: .like,
            action: action
        )
    }

    static func comment(
        count: Int,
        action: @escaping () async -> Void
    ) -> EngagementButton {
        EngagementButton(
            icon: "bubble.left",
            count: count,
            isActive: false,
            activeColor: .blue,
            animationType: .comment,
            action: action
        )
    }

    static func bookmark(
        count: Int,
        isBookmarked: Bool,
        action: @escaping () async -> Void
    ) -> EngagementButton {
        EngagementButton(
            icon: isBookmarked ? "bookmark.fill" : "bookmark",
            count: count,
            isActive: isBookmarked,
            activeColor: .primaryOrange,
            animationType: .bookmark,
            action: action
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            EngagementButton.like(count: 42, isLiked: false) {
                print("Like tapped")
            }

            EngagementButton.like(count: 1_234, isLiked: true) {
                print("Unlike tapped")
            }
        }

        HStack(spacing: 16) {
            EngagementButton.comment(count: 0) {
                print("Comment tapped")
            }

            EngagementButton.comment(count: 567) {
                print("Comment tapped")
            }
        }

        HStack(spacing: 16) {
            EngagementButton.bookmark(count: 89, isBookmarked: false) {
                print("Bookmark tapped")
            }

            EngagementButton.bookmark(count: 12_500, isBookmarked: true) {
                print("Unbookmark tapped")
            }
        }

        EngagementButton(
            icon: "star.fill",
            count: 999,
            isActive: true,
            activeColor: .yellow
        ) {
            print("Custom action")
        }
    }
    .padding()
}
