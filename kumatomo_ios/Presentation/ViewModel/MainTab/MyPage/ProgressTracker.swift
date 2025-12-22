import Foundation
import Combine

// MARK: - ProgressTracker

@MainActor
class ProgressTracker: ObservableObject {
    static let shared = ProgressTracker()

    @Published var activeOperations: [String: ProgressOperation] = [:]
    @Published var completedOperations: [CompletedOperation] = []

    private var currentOperationId: String?

    private var cancellables = Set<AnyCancellable>()
    private let maxCompletedHistory = 50

    private init() {}

    func startOperation(
        id: String = UUID().uuidString,
        title: String,
        type: OperationType,
        estimatedDuration: TimeInterval? = nil,
        isCancellable: Bool = true
    ) -> String {
        let operation = ProgressOperation(
            id: id,
            title: title,
            type: type,
            estimatedDuration: estimatedDuration,
            isCancellable: isCancellable
        )

        activeOperations[id] = operation

        print("📊 Started tracking operation: \(title) (\(id))")
        return id
    }

    func start(
        title: String = "処理中",
        type: OperationType = .updateProfile,
        estimatedDuration: TimeInterval? = nil,
        isCancellable: Bool = true
    ) {
        currentOperationId = startOperation(
            title: title,
            type: type,
            estimatedDuration: estimatedDuration,
            isCancellable: isCancellable
        )
    }

    func updateProgress(
        id: String,
        progress: Double,
        message: String? = nil,
        currentStep: String? = nil
    ) {
        guard var operation = activeOperations[id] else {
            print("⚠️ Attempted to update progress for unknown operation: \(id)")
            return
        }

        operation.progress = min(1.0, max(0.0, progress))
        operation.lastUpdated = Date()

        if let message {
            operation.statusMessage = message
        }

        if let step = currentStep {
            operation.currentStep = step
        }

        if let estimatedDuration = operation.estimatedDuration, progress > 0 {
            let elapsed = Date().timeIntervalSince(operation.startTime)
            let totalEstimated = elapsed / progress
            operation.estimatedCompletion = operation.startTime.addingTimeInterval(totalEstimated)
        }

        activeOperations[id] = operation

        print("📈 Progress updated for \(operation.title): \(Int(progress * 100))%")
    }

    func update(progress: Double, message: String? = nil, currentStep: String? = nil) {
        guard let id = currentOperationId else { return }
        updateProgress(id: id, progress: progress, message: message, currentStep: currentStep)
    }

    func completeOperation(id: String, success: Bool, result: Any? = nil, error: Error? = nil) {
        guard let operation = activeOperations[id] else {
            print("⚠️ Attempted to complete unknown operation: \(id)")
            return
        }

        let completedOperation = CompletedOperation(
            id: operation.id,
            title: operation.title,
            type: operation.type,
            startTime: operation.startTime,
            endTime: Date(),
            success: success,
            finalProgress: operation.progress,
            result: result,
            error: error
        )

        completedOperations.insert(completedOperation, at: 0)

        if completedOperations.count > maxCompletedHistory {
            completedOperations = Array(completedOperations.prefix(maxCompletedHistory))
        }

        activeOperations.removeValue(forKey: id)

        let status = success ? "✅ Completed" : "❌ Failed"
        print("\(status) operation: \(operation.title) (\(id))")
    }

    func complete(result: Any? = nil) {
        guard let id = currentOperationId else { return }
        updateProgress(id: id, progress: 1.0, message: "完了")
        completeOperation(id: id, success: true, result: result)
        currentOperationId = nil
    }

    func cancelOperation(id: String, reason: String = "User cancelled") {
        guard let operation = activeOperations[id] else {
            print("⚠️ Attempted to cancel unknown operation: \(id)")
            return
        }

        guard operation.isCancellable else {
            print("⚠️ Operation is not cancellable: \(id)")
            return
        }

        operation.cancellable?.cancel()
        operation.cancellationToken.cancel(reason: reason)

        completeOperation(
            id: id,
            success: false,
            error: ProgressError.operationCancelled(reason: reason)
        )

        print("🚫 Cancelled operation: \(operation.title) (\(id))")
    }

    func cancel(reason: String = "User cancelled") {
        guard let id = currentOperationId else { return }
        cancelOperation(id: id, reason: reason)
        currentOperationId = nil
    }

    func cancelAllOperations(reason: String = "Bulk cancellation") {
        let operationIds = Array(activeOperations.keys)

        for id in operationIds {
            cancelOperation(id: id, reason: reason)
        }

        print("🚫 Cancelled all operations: \(operationIds.count) operations")
    }

    func getProgress(id: String) -> Double? {
        return activeOperations[id]?.progress
    }

    func getStatusMessage(id: String) -> String? {
        return activeOperations[id]?.statusMessage
    }

    func getEstimatedCompletion(id: String) -> Date? {
        return activeOperations[id]?.estimatedCompletion
    }

    func isCancellable(id: String) -> Bool {
        return activeOperations[id]?.isCancellable ?? false
    }

    func getActiveOperations(ofType type: OperationType) -> [ProgressOperation] {
        return activeOperations.values.filter { $0.type == type }
    }

    func getOverallProgress(forType type: OperationType) -> Double {
        let operations = getActiveOperations(ofType: type)
        guard !operations.isEmpty else { return 0.0 }

        let totalProgress = operations.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(operations.count)
    }

    func getStatistics() -> ProgressStatistics {
        let totalCompleted = completedOperations.count
        let successfulOperations = completedOperations.filter(\.success).count
        let failedOperations = totalCompleted - successfulOperations

        let averageDuration = completedOperations.isEmpty ? 0 :
            completedOperations.map(\.duration).reduce(0, +) / Double(totalCompleted)

        let operationsByType = Dictionary(grouping: completedOperations) { $0.type }
            .mapValues { $0.count }

        let recentOperations = completedOperations.prefix(10).map { $0 }

        return ProgressStatistics(
            activeOperations: activeOperations.count,
            totalCompleted: totalCompleted,
            successfulOperations: successfulOperations,
            failedOperations: failedOperations,
            successRate: totalCompleted > 0 ? Double(successfulOperations) / Double(totalCompleted) : 0,
            averageDuration: averageDuration,
            operationsByType: operationsByType,
            recentOperations: Array(recentOperations)
        )
    }

    func clearHistory() {
        completedOperations.removeAll()
        print("🧹 Cleared completed operations history")
    }

    func getSlowOperations(threshold: TimeInterval = 30.0) -> [CompletedOperation] {
        return completedOperations.filter { $0.duration > threshold }
    }

    func getRecentFailures(since: Date = Date().addingTimeInterval(-3_600)) -> [CompletedOperation] {
        return completedOperations.filter { !$0.success && $0.endTime > since }
    }
}

// MARK: - ProgressOperation

class ProgressOperation: ObservableObject {
    let id: String
    let title: String
    let type: OperationType
    let startTime: Date
    let estimatedDuration: TimeInterval?
    let isCancellable: Bool
    let cancellationToken: CancellationToken
    var cancellable: AnyCancellable?

    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var currentStep: String = ""
    @Published var lastUpdated: Date
    @Published var estimatedCompletion: Date?

    init(
        id: String,
        title: String,
        type: OperationType,
        estimatedDuration: TimeInterval? = nil,
        isCancellable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.type = type
        startTime = Date()
        lastUpdated = Date()
        self.estimatedDuration = estimatedDuration
        self.isCancellable = isCancellable
        cancellationToken = CancellationToken()

        if let duration = estimatedDuration {
            estimatedCompletion = startTime.addingTimeInterval(duration)
        }
    }

    var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }

    var remainingTime: TimeInterval? {
        guard let completion = estimatedCompletion else { return nil }
        return max(0, completion.timeIntervalSinceNow)
    }

    var isStalled: Bool {
        return Date().timeIntervalSince(lastUpdated) > 30.0
    }
}

// MARK: - CancellationToken

class CancellationToken: ObservableObject {
    @Published private(set) var isCancelled = false
    @Published private(set) var cancellationReason: String?

    func cancel(reason: String = "Operation cancelled") {
        isCancelled = true
        cancellationReason = reason
    }

    func throwIfCancelled() throws {
        if isCancelled {
            throw ProgressError.operationCancelled(reason: cancellationReason ?? "Unknown reason")
        }
    }
}

// MARK: - CompletedOperation

struct CompletedOperation {
    let id: String
    let title: String
    let type: OperationType
    let startTime: Date
    let endTime: Date
    let success: Bool
    let finalProgress: Double
    let result: Any?
    let error: Error?

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    var wasCompleted: Bool {
        return finalProgress >= 1.0
    }
}

// MARK: - ProgressStatistics

struct ProgressStatistics {
    let activeOperations: Int
    let totalCompleted: Int
    let successfulOperations: Int
    let failedOperations: Int
    let successRate: Double
    let averageDuration: TimeInterval
    let operationsByType: [OperationType: Int]
    let recentOperations: [CompletedOperation]
}

extension ProgressTracker {
    func startProfileOperation(
        title: String,
        type: OperationType = .updateProfile,
        estimatedDuration: TimeInterval? = 10.0
    ) -> String {
        return startOperation(
            title: title,
            type: type,
            estimatedDuration: estimatedDuration,
            isCancellable: true
        )
    }

    func startImageUploadOperation(
        title: String,
        estimatedDuration: TimeInterval? = 30.0
    ) -> String {
        return startOperation(
            title: title,
            type: .uploadProfileImage,
            estimatedDuration: estimatedDuration,
            isCancellable: true
        )
    }

    func updateProgressWithSteps(
        id: String,
        currentStep: Int,
        totalSteps: Int,
        stepMessage: String
    ) {
        let progress = Double(currentStep) / Double(totalSteps)
        updateProgress(
            id: id,
            progress: progress,
            message: stepMessage,
            currentStep: "\(currentStep)/\(totalSteps)"
        )
    }

    func completeSuccessfully(id: String, result: Any? = nil) {
        updateProgress(id: id, progress: 1.0, message: "完了")
        completeOperation(id: id, success: true, result: result)
    }

    func completeWithFailure(id: String, error: Error) {
        completeOperation(id: id, success: false, error: error)
    }

    func setCancellable(_ cancellable: AnyCancellable, for id: String) {
        activeOperations[id]?.cancellable = cancellable
    }

    func setCancellable(_ cancellable: AnyCancellable) {
        guard let id = currentOperationId else { return }
        setCancellable(cancellable, for: id)
    }
}

extension ProgressTracker {
    func getFormattedProgress(id: String) -> String {
        guard let operation = activeOperations[id] else { return "0%" }
        return "\(Int(operation.progress * 100))%"
    }

    func getFormattedTimeRemaining(id: String) -> String? {
        guard let operation = activeOperations[id],
              let remaining = operation.remainingTime else { return nil }

        if remaining < 60 {
            return "\(Int(remaining))秒"
        } else if remaining < 3_600 {
            return "\(Int(remaining / 60))分"
        } else {
            return "\(Int(remaining / 3_600))時間"
        }
    }

    func getOperationStatus(id: String) -> OperationStatus {
        guard let operation = activeOperations[id] else {
            return .notFound
        }

        if operation.cancellationToken.isCancelled {
            return .cancelled
        } else if operation.isStalled {
            return .stalled
        } else if operation.progress >= 1.0 {
            return .completing
        } else if operation.progress > 0 {
            return .inProgress
        } else {
            return .starting
        }
    }
}

// MARK: - OperationStatus

enum OperationStatus {
    case notFound
    case starting
    case inProgress
    case completing
    case stalled
    case cancelled

    var displayName: String {
        switch self {
        case .notFound:
            return "見つかりません"
        case .starting:
            return "開始中"
        case .inProgress:
            return "進行中"
        case .completing:
            return "完了中"
        case .stalled:
            return "停滞中"
        case .cancelled:
            return "キャンセル済み"
        }
    }

    var color: String {
        switch self {
        case .notFound, .cancelled:
            return "gray"
        case .starting:
            return "blue"
        case .inProgress:
            return "green"
        case .completing:
            return "purple"
        case .stalled:
            return "orange"
        }
    }
}
