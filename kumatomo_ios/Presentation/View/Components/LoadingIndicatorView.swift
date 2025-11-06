import SwiftUI

struct LoadingIndicatorView: View {
    let operation: LoadingOperation
    let style: LoadingStyle

    @State private var loadingManager = LoadingStateManager.shared
    @State private var animationOffset: CGFloat = 0

    init(operation: LoadingOperation, style: LoadingStyle = .standard) {
        self.operation = operation
        self.style = style
    }

    var body: some View {
        Group {
            switch style {
            case .minimal:
                MinimalLoadingView(operation: operation)
            case .standard:
                StandardLoadingView(operation: operation)
            case .detailed:
                DetailedLoadingView(operation: operation)
            case .overlay:
                OverlayLoadingView(operation: operation)
            case .inline:
                InlineLoadingView(operation: operation)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            animationOffset = 10
        }
    }
}


enum LoadingStyle {
    case minimal
    case standard
    case detailed
    case overlay
    case inline
}


struct MinimalLoadingView: View {
    let operation: LoadingOperation

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)

            if !operation.title.isEmpty {
                Text(operation.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}


struct StandardLoadingView: View {
    let operation: LoadingOperation

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)

                if operation.showProgress {
                    Circle()
                        .trim(from: 0, to: operation.estimatedProgress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: operation.estimatedProgress)
                } else {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }

            VStack(spacing: 8) {
                Text(operation.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if let message = operation.message {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                if operation.showProgress {
                    Text("\(Int(operation.estimatedProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}


struct DetailedLoadingView: View {
    let operation: LoadingOperation
    @State private var loadingManager = LoadingStateManager.shared

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                PriorityBadge(priority: operation.priority)
                Spacer()

                if operation.isCancellable {
                    Button("キャンセル") {
                        loadingManager.cancelLoading(id: operation.id)
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }

            StandardLoadingView(operation: operation)

            if operation.showProgress {
                VStack(spacing: 12) {
                    ProgressView(value: operation.estimatedProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: priorityColor(operation.priority)))

                    if let currentStep = operation.currentStep {
                        Text(currentStep)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("経過時間: \(formatDuration(Date().timeIntervalSince(operation.startTime)))")

                        Spacer()

                        if let estimatedDuration = operation.estimatedDuration {
                            let remaining = max(0, estimatedDuration - Date().timeIntervalSince(operation.startTime))
                            Text("残り: \(formatDuration(remaining))")
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "操作ID", value: String(operation.id.prefix(8)))
                DetailRow(title: "開始時刻", value: DateFormatter.localizedString(from: operation.startTime, dateStyle: .none, timeStyle: .medium))

                if let estimatedDuration = operation.estimatedDuration {
                    DetailRow(title: "予想時間", value: formatDuration(estimatedDuration))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }

    private func priorityColor(_ priority: LoadingPriority) -> Color {
        switch priority {
        case .low:
            return .gray
        case .normal:
            return .blue
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
}


struct OverlayLoadingView: View {
    let operation: LoadingOperation

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                StandardLoadingView(operation: operation)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}


struct InlineLoadingView: View {
    let operation: LoadingOperation

    var body: some View {
        HStack(spacing: 12) {
            if operation.showProgress {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)

                    Circle()
                        .trim(from: 0, to: operation.estimatedProgress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: operation.estimatedProgress)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(operation.title)
                    .font(.body)
                    .fontWeight(.medium)

                if let message = operation.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if operation.showProgress {
                    Text("\(Int(operation.estimatedProgress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}


struct PriorityBadge: View {
    let priority: LoadingPriority

    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(8)
    }

    private var priorityColor: Color {
        switch priority {
        case .low:
            return .gray
        case .normal:
            return .blue
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}


struct GlobalLoadingOverlay: View {
    @State private var loadingManager = LoadingStateManager.shared

    var body: some View {
        ZStack {
            if loadingManager.hasActiveOperations() {
                Color.clear
                    .overlay(
                        VStack {
                            Spacer()

                            HStack {
                                Spacer()

                                if let criticalOperation = loadingManager.getCriticalOperations().first {
                                    OverlayLoadingView(operation: criticalOperation)
                                }
                                else if let highPriorityOperation = loadingManager.getHighPriorityOperations().first {
                                    VStack {
                                        Spacer()

                                        HStack {
                                            Spacer()

                                            FloatingLoadingIndicator(operation: highPriorityOperation)
                                                .padding()
                                        }
                                    }
                                }

                                Spacer()
                            }

                            Spacer()
                        }
                    )
            }
        }
        .allowsHitTesting(loadingManager.getCriticalOperations().isEmpty == false)
    }
}

struct FloatingLoadingIndicator: View {
    let operation: LoadingOperation
    @State private var loadingManager = LoadingStateManager.shared

    var body: some View {
        HStack(spacing: 12) {
            if operation.showProgress {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 30, height: 30)

                    Circle()
                        .trim(from: 0, to: operation.estimatedProgress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: operation.estimatedProgress)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.9)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(operation.title)
                    .font(.caption)
                    .fontWeight(.medium)

                if let message = operation.message {
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if operation.isCancellable {
                Button(action: {
                    loadingManager.cancelLoading(id: operation.id)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}


extension View {
    func loadingOverlay(
        isLoading: Bool,
        title: String,
        message: String? = nil,
        style: LoadingStyle = .overlay
    ) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    let operation = LoadingOperation(
                        id: UUID().uuidString,
                        title: title,
                        message: message,
                        startTime: Date()
                    )
                    LoadingIndicatorView(operation: operation, style: style)
                }
            }
        )
    }

    func loadingState(_ loadingManager: LoadingStateManager, operationId: String) -> some View {
        self.overlay(
            Group {
                if let operation = loadingManager.getLoadingOperation(id: operationId) {
                    LoadingIndicatorView(operation: operation, style: .overlay)
                }
            }
        )
    }
}


struct LoadingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingIndicatorView(
                operation: LoadingOperation(
                    id: "preview1",
                    title: "データを読み込み中",
                    message: "しばらくお待ちください",
                    startTime: Date()
                ),
                style: .standard
            )
            .previewDisplayName("Standard")

            LoadingIndicatorView(
                operation: LoadingOperation(
                    id: "preview2",
                    title: "アップロード中",
                    message: "画像を処理しています",
                    priority: .high,
                    showProgress: true,
                    estimatedDuration: 30,
                    isCancellable: true,
                    startTime: Date().addingTimeInterval(-10)
                ),
                style: .detailed
            )
            .previewDisplayName("Detailed with Progress")

            LoadingIndicatorView(
                operation: LoadingOperation(
                    id: "preview3",
                    title: "保存中",
                    startTime: Date()
                ),
                style: .inline
            )
            .previewDisplayName("Inline")
        }
    }
}
