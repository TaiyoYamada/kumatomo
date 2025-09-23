import SwiftUI

struct ErrorHandlingView: View {
    let error: AppError
    let onRetry: (() async throws -> Void)?
    let onDismiss: () -> Void
    
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var errorManager = ErrorManager.shared
    @State private var isRetrying = false
    @State private var showDiagnostics = false
    @State private var diagnostics: NetworkDiagnostics?
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            Image(systemName: errorIconName)
                .font(.system(size: 48))
                .foregroundColor(errorColor)
                .padding(.top)
            
            // Error Title
            Text(error.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Error Message
            Text(error.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Network Status Banner (if network error)
            if error.errorType == .network {
                NetworkStatusBanner()
                    .padding(.horizontal)
            }
            
            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                VStack(alignment: .leading, spacing: 8) {
                    Label("解決方法", systemImage: "lightbulb")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text(suggestion)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                // Retry Button
                if error.isRetryable, let onRetry = onRetry {
                    Button(action: {
                        Task {
                            await performRetry()
                        }
                    }) {
                        HStack {
                            if isRetrying {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(isRetrying ? "再試行中..." : "再試行")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRetrying)
                    .padding(.horizontal)
                }
                
                // Network Diagnostics Button (for network errors)
                if error.errorType == .network {
                    Button(action: {
                        Task {
                            await runDiagnostics()
                        }
                    }) {
                        HStack {
                            Image(systemName: "network")
                            Text("ネットワーク診断")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Dismiss Button
                Button(action: onDismiss) {
                    Text("閉じる")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            // Error Details (expandable)
            DisclosureGroup("エラー詳細") {
                VStack(alignment: .leading, spacing: 8) {
                    ErrorDetailRow(title: "エラータイプ", value: error.errorType.displayName)
                    ErrorDetailRow(title: "発生時刻", value: DateFormatter.localizedString(from: error.timestamp, dateStyle: .short, timeStyle: .medium))
                    ErrorDetailRow(title: "コンテキスト", value: error.context.isEmpty ? "なし" : error.context)
                    
                    if let underlyingError = error.underlyingError {
                        ErrorDetailRow(title: "詳細エラー", value: underlyingError.localizedDescription)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .sheet(isPresented: $showDiagnostics) {
            NetworkDiagnosticsView(diagnostics: diagnostics)
        }
    }
    
    private var errorIconName: String {
        switch error.errorType {
        case .network:
            return networkMonitor.isConnected ? "wifi.exclamationmark" : "wifi.slash"
        case .api:
            return "server.rack"
        case .authentication:
            return "person.crop.circle.badge.exclamationmark"
        case .authorization:
            return "lock.shield"
        case .validation:
            return "exclamationmark.triangle"
        case .fileSystem:
            return "folder.badge.exclamationmark"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private var errorColor: Color {
        switch error.errorType {
        case .network:
            return networkMonitor.isConnected ? .orange : .red
        case .api:
            return .red
        case .authentication, .authorization:
            return .yellow
        case .validation:
            return .orange
        case .fileSystem:
            return .purple
        case .unknown:
            return .gray
        }
    }
    
    private func performRetry() async {
        guard let onRetry = onRetry else { return }
        
        isRetrying = true
        
        do {
            try await onRetry()
        } catch {
            // Handle retry failure
            errorManager.handleError(error, context: "Retry failed")
        }
        
        isRetrying = false
    }
    
    private func runDiagnostics() async {
        showDiagnostics = true
        diagnostics = await networkMonitor.performNetworkDiagnostics()
    }
}

struct ErrorDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct NetworkDiagnosticsView: View {
    let diagnostics: NetworkDiagnostics?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let diagnostics = diagnostics {
                        // Overall Health
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ネットワーク状態")
                                .font(.headline)
                            
                            HStack {
                                Circle()
                                    .fill(Color(diagnostics.overallHealth.color))
                                    .frame(width: 12, height: 12)
                                
                                Text(diagnostics.overallHealth.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text(diagnostics.connectionType.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Test Results
                        VStack(alignment: .leading, spacing: 16) {
                            Text("診断結果")
                                .font(.headline)
                            
                            DiagnosticResultView(
                                title: "インターネット接続",
                                result: diagnostics.connectivityTest
                            )
                            
                            DiagnosticResultView(
                                title: "DNS解決",
                                result: diagnostics.dnsTest
                            )
                            
                            DiagnosticResultView(
                                title: "APIサーバー",
                                result: diagnostics.serverTest
                            )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Recommendations
                        if !diagnostics.recommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("推奨事項")
                                    .font(.headline)
                                
                                ForEach(diagnostics.recommendations, id: \.self) { recommendation in
                                    HStack(alignment: .top) {
                                        Image(systemName: "lightbulb")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        
                                        Text(recommendation)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Technical Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("技術詳細")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                DetailRow(title: "接続タイプ", value: diagnostics.connectionType.displayName)
                                DetailRow(title: "接続品質", value: diagnostics.connectionQuality.displayName)
                                DetailRow(title: "従量制課金", value: diagnostics.isExpensive ? "はい" : "いいえ")
                                DetailRow(title: "制限あり", value: diagnostics.isConstrained ? "はい" : "いいえ")
                                DetailRow(title: "診断時間", value: String(format: "%.2f秒", diagnostics.totalDiagnosticTime))
                                DetailRow(title: "実行時刻", value: DateFormatter.localizedString(from: diagnostics.timestamp, dateStyle: .short, timeStyle: .medium))
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        ProgressView("診断実行中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("ネットワーク診断")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DiagnosticResultView: View {
    let title: String
    let result: DiagnosticResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.0fms", result.responseTime * 1000))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let error = result.error {
                Text("エラー: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Error Type Extension

extension AppError.ErrorType {
    var displayName: String {
        switch self {
        case .network:
            return "ネットワークエラー"
        case .api:
            return "APIエラー"
        case .validation:
            return "入力エラー"
        case .authentication:
            return "認証エラー"
        case .authorization:
            return "認可エラー"
        case .fileSystem:
            return "ファイルシステムエラー"
        case .unknown:
            return "不明なエラー"
        }
    }
}

// MARK: - Preview

struct ErrorHandlingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorHandlingView(
                error: AppError.networkError(
                    URLError(.notConnectedToInternet),
                    context: "Shop list loading"
                ),
                onRetry: {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                },
                onDismiss: {}
            )
            .previewDisplayName("Network Error")
            
            ErrorHandlingView(
                error: AppError.validationError(
                    "入力された情報に問題があります",
                    context: "Form validation"
                ),
                onRetry: nil,
                onDismiss: {}
            )
            .previewDisplayName("Validation Error")
        }
    }
}
