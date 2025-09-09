import SwiftUI

struct ErrorView: View {
    let error: AppError
    let onRetry: (() async -> Void)?
    let onDismiss: () -> Void
    
    @State private var isRetrying = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Error Icon
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(iconColor)
            
            // Error Title
            Text(error.title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Error Message
            Text(error.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Context (Debug info)
            if !error.context.isEmpty {
                Text("コンテキスト: \(error.context)")
                    .font(.caption2)
//                    .foregroundColor(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                if error.isRetryable, let onRetry = onRetry {
                    Button(action: {
                        Task {
                            await handleRetry(onRetry)
                        }
                    }) {
                        HStack {
                            if isRetrying {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(isRetrying ? "再試行中..." : "再試行")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isRetrying)
                }
                
                Button(action: onDismiss) {
                    Text("閉じる")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal, 32)
    }
    
    private var iconName: String {
        switch error.errorType {
        case .network:
            return "wifi.slash"
        case .api:
            return "server.rack"
        case .validation:
            return "exclamationmark.triangle"
        case .authentication:
            return "person.crop.circle.badge.xmark"
        case .authorization:
            return "lock.slash"
        case .fileSystem:
            return "folder.badge.questionmark"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch error.errorType {
        case .network:
            return .orange
        case .api:
            return .red
        case .validation:
            return .yellow
        case .authentication, .authorization:
            return .purple
        case .fileSystem:
            return .blue
        case .unknown:
            return .gray
        }
    }
    
    private func handleRetry(_ retryAction: @escaping () async -> Void) async {
        isRetrying = true
        
        do {
            await retryAction()
        } catch {
            // Error will be handled by ErrorManager
            print("Retry failed: \(error)")
        }
        
        isRetrying = false
    }
}

// MARK: - Network Status Banner (removed duplicate - using NetworkStatusBanner.swift)

// MARK: - Error Toast

struct ErrorToast: View {
    let error: AppError
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(error.message)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(toastColor)
        .cornerRadius(8)
        .shadow(radius: 4)
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = true
            }
            
            // Auto dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            }
        }
    }
    
    private var toastColor: Color {
        switch error.errorType {
        case .network:
            return .orange
        case .api:
            return .red
        case .validation:
            return .yellow
        case .authentication, .authorization:
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Error Overlay Modifier

struct ErrorOverlayModifier: ViewModifier {
    @ObservedObject private var errorManager = ErrorManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if errorManager.isShowingError, let error = errorManager.currentError {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                errorManager.dismissError()
                            }
                        
                        ErrorView(
                            error: error,
                            onRetry: error.isRetryable ? {
                                await errorManager.retryLastOperation()
                            } : nil,
                            onDismiss: {
                                errorManager.dismissError()
                            }
                        )
                    }
                }
            )
    }
}

extension View {
    func errorOverlay() -> some View {
        modifier(ErrorOverlayModifier())
    }
}
