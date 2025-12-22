import SwiftUI

// MARK: - SkeletonLoadingView

struct SkeletonLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< 5, id: \.self) { _ in
                SkeletonPostItem()

                Rectangle()
                    .fill(Color(hex: "E5E7EB"))
                    .frame(height: 1)
                    .accessibilityHidden(true)
            }
        }
        .background(Color.white)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - SkeletonPostItem

struct SkeletonPostItem: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .shimmer(offset: shimmerOffset)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 16)
                        .cornerRadius(4)
                        .shimmer(offset: shimmerOffset)

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 14)
                        .cornerRadius(4)
                        .shimmer(offset: shimmerOffset)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .cornerRadius(4)
                        .shimmer(offset: shimmerOffset)

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 16)
                        .cornerRadius(4)
                        .shimmer(offset: shimmerOffset)
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .cornerRadius(12)
                    .shimmer(offset: shimmerOffset)

                HStack(spacing: 16) {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .shimmer(offset: shimmerOffset)

                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 20, height: 14)
                                .cornerRadius(4)
                                .shimmer(offset: shimmerOffset)
                        }
                    }

                    Spacer()

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                        .shimmer(offset: shimmerOffset)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - ErrorStateView

struct ErrorStateView: View {
    let error: String
    let onRetry: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var adaptiveTitleSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 16
        case .medium:
            return 18
        case .large:
            return 20
        case .xLarge:
            return 22
        case .xxLarge:
            return 24
        case .xxxLarge:
            return 26
        default:
            return 18
        }
    }

    private var adaptiveErrorSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 12
        case .medium:
            return 14
        case .large:
            return 16
        case .xLarge:
            return 17
        case .xxLarge:
            return 18
        case .xxxLarge:
            return 20
        default:
            return 14
        }
    }

    private var adaptiveButtonSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 17
        case .xLarge:
            return 18
        case .xxLarge:
            return 20
        case .xxxLarge:
            return 22
        default:
            return 16
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "EF4444"))

            VStack(spacing: 8) {
                Text("エラーが発生しました")
                    .font(.system(size: adaptiveTitleSize, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)

                Text(error)
                    .font(.system(size: adaptiveErrorSize))
                    .foregroundColor(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: adaptiveButtonSize - 2, weight: .medium))

                    Text("再試行")
                        .font(.system(size: adaptiveButtonSize, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "1DA1F2"))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(minHeight: 44)
        }
        .padding(.horizontal, 32)
        .padding(.top, 100)
    }
}

// MARK: - NetworkErrorView

struct NetworkErrorView: View {
    let onRetry: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var adaptiveTitleSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 16
        case .medium:
            return 18
        case .large:
            return 20
        case .xLarge:
            return 22
        case .xxLarge:
            return 24
        case .xxxLarge:
            return 26
        default:
            return 18
        }
    }

    private var adaptiveSubtitleSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 12
        case .medium:
            return 14
        case .large:
            return 16
        case .xLarge:
            return 17
        case .xxLarge:
            return 18
        case .xxxLarge:
            return 20
        default:
            return 14
        }
    }

    private var adaptiveButtonSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 17
        case .xLarge:
            return 18
        case .xxLarge:
            return 20
        case .xxxLarge:
            return 22
        default:
            return 16
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "6B7280"))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("ネットワークに接続できません")
                    .font(.system(size: adaptiveTitleSize, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)

                Text("インターネット接続を確認してください")
                    .font(.system(size: adaptiveSubtitleSize))
                    .foregroundColor(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
            }

            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: adaptiveButtonSize - 2, weight: .medium))

                    Text("再試行")
                        .font(.system(size: adaptiveButtonSize, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "1DA1F2"))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(minHeight: 44)
        }
        .padding(.horizontal, 32)
        .padding(.top, 100)
    }
}

// MARK: - PaginationLoadingView

struct PaginationLoadingView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var adaptiveTextSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 10
        case .medium:
            return 12
        case .large:
            return 13
        case .xLarge:
            return 14
        case .xxLarge:
            return 15
        case .xxxLarge:
            return 16
        default:
            return 12
        }
    }

    var body: some View {
        HStack {
            Spacer()

            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)

                Text("読み込み中...")
                    .font(.system(size: adaptiveTextSize))
                    .foregroundColor(Color(hex: "6B7280"))
            }

            Spacer()
        }
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("追加の投稿を読み込み中")
        .accessibilityIdentifier("pagination_loading_view")
    }
}

// MARK: - RefreshLoadingView

struct RefreshLoadingView: View {
    var body: some View {
        HStack {
            Spacer()

            ProgressView()
                .scaleEffect(1.2)
                .tint(Color(hex: "1DA1F2"))

            Spacer()
        }
        .padding(.vertical, 40)
    }
}

// MARK: - ShimmerEffect

struct ShimmerEffect: ViewModifier {
    let offset: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: offset)
                    .clipped()
            )
            .clipped()
    }
}

extension View {
    func shimmer(offset: CGFloat) -> some View {
        modifier(ShimmerEffect(offset: offset))
    }
}

// MARK: - ToastView

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    enum ToastType {
        case success
        case error
        case info

        var color: Color {
            switch self {
            case .success:
                return Color(hex: "10B981")
            case .error:
                return Color(hex: "EF4444")
            case .info:
                return Color(hex: "1DA1F2")
            }
        }

        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "exclamationmark.circle.fill"
            case .info:
                return "info.circle.fill"
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .success:
                return "成功"
            case .error:
                return "エラー"
            case .info:
                return "情報"
            }
        }
    }

    private var adaptiveTextSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 12
        case .medium:
            return 14
        case .large:
            return 15
        case .xLarge:
            return 16
        case .xxLarge:
            return 17
        case .xxxLarge:
            return 18
        default:
            return 14
        }
    }

    private var adaptiveIconSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 10
        case .medium:
            return 12
        case .large:
            return 13
        case .xLarge:
            return 14
        case .xxLarge:
            return 15
        case .xxxLarge:
            return 16
        default:
            return 12
        }
    }

    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .accessibilityHidden(true)

                Text(message)
                    .font(.system(size: adaptiveTextSize, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button(action: { isShowing = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: adaptiveIconSize, weight: .medium))
                        .foregroundColor(Color(hex: "6B7280"))
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}
