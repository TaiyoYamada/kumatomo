import SwiftUI

struct ActionButton: View {
    let icon: String
    let count: Int
    let color: Color
    let activeColor: Color
    var isActive: Bool = false
    var action: (() -> Void)? = nil
    
    init(
        icon: String,
        count: Int = 0,
        color: Color = .secondary,
        activeColor: Color = .blue,
        isActive: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.count = count
        self.color = color
        self.activeColor = activeColor
        self.isActive = isActive
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isActive ? activeColor : color)
                
                if count > 0 {
                    Text(formatCount(count))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isActive ? activeColor : color)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? activeColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Specialized Action Buttons

struct LikeButton: View {
    let count: Int
    let isLiked: Bool
    let onTap: () -> Void
    
    var body: some View {
        ActionButton(
            icon: isLiked ? "heart.fill" : "heart",
            count: count,
            color: .secondary,
            activeColor: .red,
            isActive: isLiked,
            action: onTap
        )
    }
}

struct CommentButton: View {
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        ActionButton(
            icon: "message",
            count: count,
            color: .secondary,
            activeColor: .blue,
            action: onTap
        )
    }
}

struct ShareButton: View {
    let count: Int
    let isShared: Bool
    let onTap: () -> Void
    
    var body: some View {
        ActionButton(
            icon: "arrow.2.squarepath",
            count: count,
            color: .secondary,
            activeColor: .green,
            isActive: isShared,
            action: onTap
        )
    }
}

struct BookmarkButton: View {
    let isBookmarked: Bool
    let onTap: () -> Void
    
    var body: some View {
        ActionButton(
            icon: isBookmarked ? "bookmark.fill" : "bookmark",
            color: .secondary,
            activeColor: .orange,
            isActive: isBookmarked,
            action: onTap
        )
    }
}

// MARK: - Preview

#if DEBUG
struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                LikeButton(count: 42, isLiked: false) {}
                CommentButton(count: 12) {}
                ShareButton(count: 5, isShared: false) {}
                BookmarkButton(isBookmarked: false) {}
            }
            
            HStack(spacing: 16) {
                LikeButton(count: 1250, isLiked: true) {}
                CommentButton(count: 89) {}
                ShareButton(count: 23, isShared: true) {}
                BookmarkButton(isBookmarked: true) {}
            }
        }
        .padding()
    }
}
#endif