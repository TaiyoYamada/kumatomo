import Foundation
import Combine

// MARK: - Progress Tracker for Long-Running Operations

@MainActor
class ProgressTracker: ObservableObject {
    static let shared = ProgressTracker()
    
    @Published var activeOperations: [String: ProgressOperation] = [:]
    @Published var completedOperations: [CompletedOperation] = []
    
    // Tracks the most-recent started operation for shorthand APIs
    private var currentOperationId: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let maxCompletedHistory = 50
    
    private init() {}
    
    // MARK: - Progress Management
    
    /// Starts tracking progress for an operation
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
    
    /// Shorthand: start a generic operation and remember it as current
    func start(title: String = "処理中", type: OperationType = .updateProfile, estimatedDuration: TimeInterval? = nil, isCancellable: Bool = true) {
        currentOperationId = startOperation(
            title: title,
            type: type,
            estimatedDuration: estimatedDuration,
            isCancellable: isCancellable
        )
    }
    
    /// Updates progress for an operation
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
        
        if let message = message {
            operation.statusMessage = message
        }
        
        if let step = currentStep {
            operation.currentStep = step
        }
        
        // Update estimated completion time
        if let estimatedDuration = operation.estimatedDuration, progress > 0 {
            let elapsed = Date().timeIntervalSince(operation.startTime)
            let totalEstimated = elapsed / progress
            operation.estimatedCompletion = operation.startTime.addingTimeInterval(totalEstimated)
        }
        
        activeOperations[id] = operation
        
        print("📈 Progress updated for \(operation.title): \(Int(progress * 100))%")
    }
    
    /// Shorthand: update current operation's progress
    func update(progress: Double, message: String? = nil, currentStep: String? = nil) {
        guard let id = currentOperationId else { return }
        updateProgress(id: id, progress: progress, message: message, currentStep: currentStep)
    }
    
    /// Completes an operation
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
        
        // Add to completed history
        completedOperations.insert(completedOperation, at: 0)
        
        // Maintain history size limit
        if completedOperations.count > maxCompletedHistory {
            completedOperations = Array(completedOperations.prefix(maxCompletedHistory))
        }
        
        // Remove from active operations
        activeOperations.removeValue(forKey: id)
        
        let status = success ? "✅ Completed" : "❌ Failed"
        print("\(status) operation: \(operation.title) (\(id))")
    }
    
    /// Shorthand: complete current operation successfully
    func complete(result: Any? = nil) {
        guard let id = currentOperationId else { return }
        updateProgress(id: id, progress: 1.0, message: "完了")
        completeOperation(id: id, success: true, result: result)
        currentOperationId = nil
    }
    
    /// Cancels an operation
    func cancelOperation(id: String, reason: String = "User cancelled") {
        guard let operation = activeOperations[id] else {
            print("⚠️ Attempted to cancel unknown operation: \(id)")
            return
        }
        
        guard operation.isCancellable else {
            print("⚠️ Operation is not cancellable: \(id)")
            return
        }
        
        // Mark as cancelled
        operation.cancellable?.cancel()
        operation.cancellationToken.cancel(reason: reason)
        
        // Complete with cancellation
        completeOperation(
            id: id,
            success: false,
            error: ProgressError.operationCancelled(reason: reason)
        )
        
        print("🚫 Cancelled operation: \(operation.title) (\(id))")
    }
    
    /// Shorthand: cancel current operation
    func cancel(reason: String = "User cancelled") {
        guard let id = currentOperationId else { return }
        cancelOperation(id: id, reason: reason)
        currentOperationId = nil
    }
    
    /// Cancels all active operations
    func cancelAllOperations(reason: String = "Bulk cancellation") {
        let operationIds = Array(activeOperations.keys)
        
        for id in operationIds {
            cancelOperation(id: id, reason: reason)
        }
        
        print("🚫 Cancelled all operations: \(operationIds.count) operations")
    }
    
    // MARK: - Operation Queries
    
    /// Gets progress for a specific operation
    func getProgress(id: String) -> Double? {
        return activeOperations[id]?.progress
    }
    
    /// Gets status message for a specific operation
    func getStatusMessage(id: String) -> String? {
        return activeOperations[id]?.statusMessage
    }
    
    /// Gets estimated completion time for an operation
    func getEstimatedCompletion(id: String) -> Date? {
        return activeOperations[id]?.estimatedCompletion
    }
    
    /// Checks if an operation is cancellable
    func isCancellable(id: String) -> Bool {
        return activeOperations[id]?.isCancellable ?? false
    }
    
    /// Gets all active operations of a specific type
    func getActiveOperations(ofType type: OperationType) -> [ProgressOperation] {
        return activeOperations.values.filter { $0.type == type }
    }
    
    /// Gets overall progress for all operations of a type
    func getOverallProgress(forType type: OperationType) -> Double {
        let operations = getActiveOperations(ofType: type)
        guard !operations.isEmpty else { return 0.0 }
        
        let totalProgress = operations.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(operations.count)
    }
    
    // MARK: - Statistics and History
    
    /// Gets statistics for completed operations
    func getStatistics() -> ProgressStatistics {
        let totalCompleted = completedOperations.count
        let successfulOperations = completedOperations.filter { $0.success }.count
        let failedOperations = totalCompleted - successfulOperations
        
        let averageDuration = completedOperations.isEmpty ? 0 :
            completedOperations.map { $0.duration }.reduce(0, +) / Double(totalCompleted)
        
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
    
    /// Clears completed operations history
    func clearHistory() {
        completedOperations.removeAll()
        print("🧹 Cleared completed operations history")
    }
    
    /// Gets operations that took longer than expected
    func getSlowOperations(threshold: TimeInterval = 30.0) -> [CompletedOperation] {
        return completedOperations.filter { $0.duration > threshold }
    }
    
    /// Gets recently failed operations
    func getRecentFailures(since: Date = Date().addingTimeInterval(-3600)) -> [CompletedOperation] {
        return completedOperations.filter { !$0.success && $0.endTime > since }
    }
}

// MARK: - Supporting Types

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
        self.startTime = Date()
        self.lastUpdated = Date()
        self.estimatedDuration = estimatedDuration
        self.isCancellable = isCancellable
        self.cancellationToken = CancellationToken()
        
        if let duration = estimatedDuration {
            self.estimatedCompletion = startTime.addingTimeInterval(duration)
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
        return Date().timeIntervalSince(lastUpdated) > 30.0 // No update for 30 seconds
    }
}

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

enum ProgressError: LocalizedError {
    case operationCancelled(reason: String)
    case operationTimeout
    case operationFailed(underlying: Error)
    case invalidOperation
    
    var errorDescription: String? {
        switch self {
        case .operationCancelled(let reason):
            return "操作がキャンセルされました: \(reason)"
        case .operationTimeout:
            return "操作がタイムアウトしました"
        case .operationFailed(let error):
            return "操作が失敗しました: \(error.localizedDescription)"
        case .invalidOperation:
            return "無効な操作です"
        }
    }
}

// MARK: - Convenience Extensions

extension ProgressTracker {
    /// Convenience method for profile operations
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
    
    /// Convenience method for image upload operations
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
    
    /// Updates progress with automatic step calculation
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
    
    /// Completes operation with success
    func completeSuccessfully(id: String, result: Any? = nil) {
        updateProgress(id: id, progress: 1.0, message: "完了")
        completeOperation(id: id, success: true, result: result)
    }
    
    /// Completes operation with failure
    func completeWithFailure(id: String, error: Error) {
        completeOperation(id: id, success: false, error: error)
    }
    
    /// Assigns a cancellable to an operation for cooperative cancellation
    func setCancellable(_ cancellable: AnyCancellable, for id: String) {
        activeOperations[id]?.cancellable = cancellable
    }
    
    /// Shorthand: assigns cancellable to the current operation
    func setCancellable(_ cancellable: AnyCancellable) {
        guard let id = currentOperationId else { return }
        setCancellable(cancellable, for: id)
    }
}

// MARK: - SwiftUI Integration

extension ProgressTracker {
    /// Gets a formatted progress string
    func getFormattedProgress(id: String) -> String {
        guard let operation = activeOperations[id] else { return "0%" }
        return "\(Int(operation.progress * 100))%"
    }
    
    /// Gets a formatted time remaining string
    func getFormattedTimeRemaining(id: String) -> String? {
        guard let operation = activeOperations[id],
              let remaining = operation.remainingTime else { return nil }
        
        if remaining < 60 {
            return "\(Int(remaining))秒"
        } else if remaining < 3600 {
            return "\(Int(remaining / 60))分"
        } else {
            return "\(Int(remaining / 3600))時間"
        }
    }
    
    /// Gets operation status for UI display
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
