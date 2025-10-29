import SwiftUI

/// A reusable engagement button component for likes, comments, and bookmarks
struct EngagementButton: View {
    let icon: String
    let count: Int
    let isActive: Bool
    let activeColor: Color
    let action: () async -> Void
    
    // Animation and interaction state
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    
    
    init(
        icon: String,
        count: Int,
        isActive: Bool = false,
        activeColor: Color = .primaryOrange,
        action: @escaping () async -> Void
    ) {
        self.icon = icon
        self.count = count
        self.isActive = isActive
        self.activeColor = activeColor
        self.action = action
    }
    
    var body: some View {
        Button {
            Task {
                await performAction()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(buttonColor)
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scale)
                
                if count > 0 {
                    Text(count.formatCount())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        // Use a custom button style to provide pressed feedback without
        // interfering with tap recognition on iOS (no gesture hacks).
        .buttonStyle(PressEffectButtonStyle())
    }
    
    // MARK: - Private Methods
    
    private func performAction() async {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Scale animation for tap feedback
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            scale = 1.2
        }
        
        // Perform the action
        await action()
        
        // Reset scale
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.0
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonColor: Color {
        if isActive {
            return activeColor
        } else {
            return Color.primary.opacity(0.6)
        }
    }
    
    private var textColor: Color {
        if isActive {
            return activeColor
        } else {
            return Color.primary.opacity(0.7)
        }
    }
    
    private var backgroundColor: Color {
        if isActive {
            return activeColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Button Style

/// A button style that provides subtle press feedback using configuration.isPressed
/// This avoids gesture conflicts on iOS that can swallow taps when combined
/// with ScrollViews or other recognizers.
struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Convenience Initializers

extension EngagementButton {
    /// Creates a like button
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
            action: action
        )
    }
    
    /// Creates a comment button
    static func comment(
        count: Int,
        action: @escaping () async -> Void
    ) -> EngagementButton {
        EngagementButton(
            icon: "bubble.left",
            count: count,
            isActive: false,
            activeColor: .blue,
            action: action
        )
    }
    
    /// Creates a bookmark button
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
            action: action
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Like button examples
        HStack(spacing: 16) {
            EngagementButton.like(count: 42, isLiked: false) {
                print("Like tapped")
            }
            
            EngagementButton.like(count: 1234, isLiked: true) {
                print("Unlike tapped")
            }
        }
        
        // Comment button examples
        HStack(spacing: 16) {
            EngagementButton.comment(count: 0) {
                print("Comment tapped")
            }
            
            EngagementButton.comment(count: 567) {
                print("Comment tapped")
            }
        }
        
        // Bookmark button examples
        HStack(spacing: 16) {
            EngagementButton.bookmark(count: 89, isBookmarked: false) {
                print("Bookmark tapped")
            }
            
            EngagementButton.bookmark(count: 12500, isBookmarked: true) {
                print("Unbookmark tapped")
            }
        }
        
        // Custom button example
        EngagementButton(
            icon: "star.fill",
            count: 999,
            isActive: true,
            activeColor: .yellow,
        ) {
            print("Custom action")
        }
    }
    .padding()
}
