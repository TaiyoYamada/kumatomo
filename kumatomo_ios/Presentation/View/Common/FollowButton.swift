import SwiftUI

// MARK: - FollowButton

/// フォロー/フォロー解除ボタンコンポーネント
struct FollowButton: View {
    let isFollowing: Bool
    let isLoading: Bool
    let onTap: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var buttonTextSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 12
        case .medium:
            return 14
        case .large:
            return 15
        case .xLarge:
            return 16
        default:
            return 14
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(isFollowing ? Color.primaryOrange : .white)
                } else {
                    if isFollowing {
                        Image(systemName: "checkmark")
                            .font(.system(size: buttonTextSize - 2, weight: .medium))
                    }
                    Text(isFollowing ? "フォロー中" : "フォロー")
                        .font(.system(size: buttonTextSize, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isFollowing
                    ? Color.white
                    : Color.primaryOrange
            )
            .foregroundColor(
                isFollowing
                    ? Color.primaryOrange
                    : .white
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primaryOrange, lineWidth: isFollowing ? 1.5 : 0)
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isFollowing)
    }
}

// MARK: - CompactFollowButton

/// コンパクト版フォローボタン（リスト用）
struct CompactFollowButton: View {
    let isFollowing: Bool
    let isLoading: Bool
    let isMe: Bool
    let onTap: () -> Void

    var body: some View {
        if isMe {
            EmptyView()
        } else {
            Button(action: onTap) {
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 70, height: 28)
                    } else {
                        Text(isFollowing ? "フォロー中" : "フォロー")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 70, height: 28)
                    }
                }
                .background(
                    isFollowing
                        ? Color(.systemGray5)
                        : Color.primaryOrange
                )
                .foregroundColor(
                    isFollowing
                        ? .primary
                        : .white
                )
                .cornerRadius(14)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading)
        }
    }
}

// MARK: - Preview

//
// #Preview {
//    VStack(spacing: 20) {
//        FollowButton(isFollowing: false, isLoading: false) {}
//        FollowButton(isFollowing: true, isLoading: false) {}
//        FollowButton(isFollowing: false, isLoading: true) {}
//
//        Divider()
//
//        HStack {
//            CompactFollowButton(isFollowing: false, isLoading: false, isMe: false) {}
//            CompactFollowButton(isFollowing: true, isLoading: false, isMe: false) {}
//            CompactFollowButton(isFollowing: false, isLoading: true, isMe: false) {}
//        }
//    }
//    .padding()
// }
