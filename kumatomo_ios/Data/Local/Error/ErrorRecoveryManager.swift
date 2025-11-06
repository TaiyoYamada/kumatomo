import Foundation
import SwiftUI
import Combine


@MainActor
class ErrorRecoveryManager: ObservableObject {
    static let shared = ErrorRecoveryManager()

    @Published var recoveryActions: [String: RecoveryAction] = [:]
    @Published var recoveryHistory: [RecoveryHistoryEntry] = []
    @Published var isRecovering = false

    private var cancellables = Set<AnyCancellable>()
    private let maxHistoryEntries = 50

    private init() {
        setupDefaultRecoveryActions()
    }


    func registerRecoveryAction(
        for errorType: String,
        action: @escaping () async throws -> Void,
        description: String,
        priority: RecoveryPriority = .medium
    ) {
        let recoveryAction = RecoveryAction(
            id: UUID().uuidString,
            errorType: errorType,
            description: description,
            priority: priority,
            action: action,
            registeredAt: Date()
        )

        recoveryActions[errorType] = recoveryAction
    }

    func attemptRecovery(from error: ProfileError) async -> RecoveryResult {
        let errorType = String(describing: error.errorCategory)

        guard let recoveryAction = recoveryActions[errorType] else {
            return .noRecoveryAvailable
        }

        isRecovering = true
        let startTime = Date()

        defer {
            isRecovering = false
        }

        do {
            try await recoveryAction.action()

            let historyEntry = RecoveryHistoryEntry(
                errorType: errorType,
                recoveryDescription: recoveryAction.description,
                result: .success,
                timestamp: Date(),
                duration: Date().timeIntervalSince(startTime)
            )

            addToHistory(historyEntry)
            return .success

        } catch {
            let historyEntry = RecoveryHistoryEntry(
                errorType: errorType,
                recoveryDescription: recoveryAction.description,
                result: .failed(error),
                timestamp: Date(),
                duration: Date().timeIntervalSince(startTime)
            )

            addToHistory(historyEntry)
            return .failed(error)
        }
    }

    func getRecoveryActions(for error: ProfileError) -> [RecoveryAction] {
        let errorType = String(describing: error.errorCategory)

        if let action = recoveryActions[errorType] {
            return [action]
        }

        return getGenericRecoveryActions(for: error)
    }


    private func setupDefaultRecoveryActions() {
        registerRecoveryAction(
            for: "network",
            action: {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            },
            description: "ネットワーク接続を再確認",
            priority: .high
        )

        registerRecoveryAction(
            for: "authentication",
            action: {
                try await AuthService.shared.refreshToken()
            },
            description: "認証情報を更新",
            priority: .high
        )

        registerRecoveryAction(
            for: "data",
            action: {
                await ProfileCache.shared.clearCache()
                try await ProfileCache.shared.reloadFromServer()
            },
            description: "データを再同期",
            priority: .medium
        )

        registerRecoveryAction(
            for: "media",
            action: {
                await ImageCache.shared.clearCache()
            },
            description: "画像キャッシュをクリア",
            priority: .low
        )

        registerRecoveryAction(
            for: "server",
            action: {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            },
            description: "サーバー状態を確認",
            priority: .medium
        )
    }

    private func getGenericRecoveryActions(for error: ProfileError) -> [RecoveryAction] {
        var actions: [RecoveryAction] = []

        if error.isRecoverable {
            let retryAction = RecoveryAction(
                id: "generic-retry",
                errorType: "generic",
                description: "操作を再試行",
                priority: .medium,
                action: {
                    throw RecoveryError.genericRetryNotImplemented
                },
                registeredAt: Date()
            )
            actions.append(retryAction)
        }

        if error.severity == .critical {
            let restartAction = RecoveryAction(
                id: "app-restart",
                errorType: "generic",
                description: "アプリを再起動",
                priority: .low,
                action: {
                    throw RecoveryError.appRestartRequired
                },
                registeredAt: Date()
            )
            actions.append(restartAction)
        }

        return actions
    }


    private func addToHistory(_ entry: RecoveryHistoryEntry) {
        recoveryHistory.insert(entry, at: 0)

        if recoveryHistory.count > maxHistoryEntries {
            recoveryHistory = Array(recoveryHistory.prefix(maxHistoryEntries))
        }
    }

    func clearHistory() {
        recoveryHistory.removeAll()
    }


    func getRecoveryStatistics() -> RecoveryStatistics {
        let totalAttempts = recoveryHistory.count
        let successfulAttempts = recoveryHistory.filter { $0.result.isSuccess }.count
        let failedAttempts = totalAttempts - successfulAttempts

        let averageDuration = recoveryHistory.isEmpty ? 0 :
            recoveryHistory.reduce(0) { $0 + $1.duration } / Double(totalAttempts)

        let errorTypeFrequency = Dictionary(grouping: recoveryHistory, by: { $0.errorType })
            .mapValues { $0.count }

        return RecoveryStatistics(
            totalAttempts: totalAttempts,
            successfulAttempts: successfulAttempts,
            failedAttempts: failedAttempts,
            successRate: totalAttempts > 0 ? Double(successfulAttempts) / Double(totalAttempts) : 0,
            averageDuration: averageDuration,
            errorTypeFrequency: errorTypeFrequency
        )
    }
}


struct RecoveryAction {
    let id: String
    let errorType: String
    let description: String
    let priority: RecoveryPriority
    let action: () async throws -> Void
    let registeredAt: Date
}

enum RecoveryPriority: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4

    var description: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "緊急"
        }
    }
}

enum RecoveryResult {
    case success
    case failed(Error)
    case noRecoveryAvailable

    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

struct RecoveryHistoryEntry {
    let id = UUID()
    let errorType: String
    let recoveryDescription: String
    let result: RecoveryResult
    let timestamp: Date
    let duration: TimeInterval
}

struct RecoveryStatistics {
    let totalAttempts: Int
    let successfulAttempts: Int
    let failedAttempts: Int
    let successRate: Double
    let averageDuration: TimeInterval
    let errorTypeFrequency: [String: Int]
}

enum RecoveryError: LocalizedError {
    case genericRetryNotImplemented
    case appRestartRequired
    case recoveryActionNotFound
    case recoveryTimeout

    var errorDescription: String? {
        switch self {
        case .genericRetryNotImplemented:
            return "汎用リトライが実装されていません"
        case .appRestartRequired:
            return "アプリの再起動が必要です"
        case .recoveryActionNotFound:
            return "復旧アクションが見つかりません"
        case .recoveryTimeout:
            return "復旧処理がタイムアウトしました"
        }
    }
}




extension ErrorRecoveryManager {
    func recoveryActionSheet(for error: ProfileError) -> ActionSheet {
        let actions = getRecoveryActions(for: error)

        var buttons: [ActionSheet.Button] = actions.map { action in
            .default(Text(action.description)) {
                Task {
                    _ = await self.attemptRecovery(from: error)
                }
            }
        }

        buttons.append(.cancel(Text("キャンセル")))

        return ActionSheet(
            title: Text("復旧オプション"),
            message: Text("以下の復旧方法を試すことができます"),
            buttons: buttons
        )
    }

    func recoveryButton(for error: ProfileError) -> some View {
        Button("復旧を試行") {
            Task {
                _ = await self.attemptRecovery(from: error)
            }
        }
        .disabled(isRecovering)
    }
}
