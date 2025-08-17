import SwiftUI

// MARK: - Loading States

struct SkeletonLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonPostItem()
                
                Rectangle()
                    .fill(Color(hex: "E5E7EB"))
                    .frame(height: 1)
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

struct SkeletonPostItem: View {
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Profile skeleton
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .shimmer(offset: shimmerOffset)
            
            VStack(alignment: .leading, spacing: 8) {
                // User info skeleton
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
                
                // Content skeleton
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
                
                // Image skeleton
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .cornerRadius(12)
                    .shimmer(offset: shimmerOffset)
                
                // Action bar skeleton
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
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

// MARK: - Error States

struct ErrorStateView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "EF4444"))
            
            VStack(spacing: 8) {
                Text("エラーが発生しました")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("再試行")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "1DA1F2"))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.top, 100)
    }
}

struct NetworkErrorView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "6B7280"))
            
            VStack(spacing: 8) {
                Text("ネットワークに接続できません")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                
                Text("インターネット接続を確認してください")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("再試行")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "1DA1F2"))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.top, 100)
    }
}

// MARK: - Loading Indicators

struct PaginationLoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("読み込み中...")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "6B7280"))
            }
            
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

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

// MARK: - Shimmer Effect

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
        self.modifier(ShimmerEffect(offset: offset))
    }
}

// MARK: - Toast Notifications

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
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
    }
    
    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                
                Spacer()
                
                Button(action: { isShowing = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "6B7280"))
                }
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

#Preview("Skeleton Loading") {
    SkeletonLoadingView()
}

#Preview("Error State") {
    ErrorStateView(error: "サーバーに接続できませんでした") {
        print("Retry tapped")
    }
}

#Preview("Network Error") {
    NetworkErrorView {
        print("Retry tapped")
    }
}