import Foundation
import SwiftUI
import Combine
import Observation

@MainActor
@Observable
class LoadingStateManager {
    static let shared = LoadingStateManager()
    
    var activeOperations: [String: LoadingOperation] = [:]
    var globalLoadingState: GlobalLoadingState = .idle
    var loadingHistory: [LoadingHistoryEntry] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let maxHistoryEntries = 100
    
    private init() {}
    
    private func recomputeGlobalState() {
        let operations = activeOperations
        if operations.isEmpty {
            globalLoadingState = .idle
        } else if operations.values.contains(where: { $0.priority == .critical }) {
            globalLoadingState = .critical
        } else if operations.values.contains(where: { $0.priority == .high }) {
            globalLoadingState = .busy
        } else {
            globalLoadingState = .loading
        }
    }
    
    // MARK: - Loading Operation Management
    
    func startLoading(
        id: String = UUID().uuidString,
        title: String,
        message: String? = nil,
        priority: LoadingPriority = .normal,
        showProgress: Bool = false,
        estimatedDuration: TimeInterval? = nil,
        isCancellable: Bool = false
    ) -> String {
        let operation = LoadingOperation(
            id: id,
            title: title,
            message: message,
            priority: priority,
            showProgress: showProgress,
            estimatedDuration: estimatedDuration,
            isCancellable: isCancellable,
            startTime: Date()
        )
        
        activeOperations[id] = operation
        recomputeGlobalState()
        
        logLoadingEvent(.started, operation: operation)
        
        return id
    }
    
    func updateLoading(
        id: String,
        message: String? = nil,
        progress: Double? = nil,
        currentStep: String? = nil
    ) {
        guard var operation = activeOperations[id] else {
            print("⚠️ Loading operation not found: \(id)")
            return
        }
        
        if let message = message {
            operation.message = message
        }
        
        if let progress = progress {
            operation.progress = max(0, min(1, progress))
        }
        
        if let currentStep = currentStep {
            operation.currentStep = currentStep
        }
        
        operation.lastUpdated = Date()
        activeOperations[id] = operation
        recomputeGlobalState()
        
        logLoadingEvent(.updated, operation: operation)
    }
    
    func completeLoading(id: String, result: LoadingResult = .success) {
        guard let operation = activeOperations[id] else {
            print("⚠️ Loading operation not found: \(id)")
            return
        }
        
        var completedOperation = operation
        completedOperation.result = result
        completedOperation.endTime = Date()
        
        activeOperations.removeValue(forKey: id)
        recomputeGlobalState()
        
        logLoadingEvent(.completed, operation: completedOperation)
        addToHistory(completedOperation)
    }
    
    func cancelLoading(id: String, reason: String = "User cancelled") {
        guard let operation = activeOperations[id] else {
            print("⚠️ Loading operation not found: \(id)")
            return
        }
        
        var cancelledOperation = operation
        cancelledOperation.result = .cancelled(reason: reason)
        cancelledOperation.endTime = Date()
        
        activeOperations.removeValue(forKey: id)
        recomputeGlobalState()
        
        logLoadingEvent(.cancelled, operation: cancelledOperation)
        addToHistory(cancelledOperation)
    }
    
    func cancelAllLoading(reason: String = "Bulk cancellation") {
        let operationIds = Array(activeOperations.keys)
        
        for id in operationIds {
            cancelLoading(id: id, reason: reason)
        }
        
        print("🚫 Cancelled all loading operations: \(reason)")
    }
    
    // MARK: - State Queries
    
    func isLoading(id: String) -> Bool {
        return activeOperations[id] != nil
    }
    
    func getLoadingOperation(id: String) -> LoadingOperation? {
        return activeOperations[id]
    }
    
    func hasActiveOperations() -> Bool {
        return !activeOperations.isEmpty
    }
    
    func getActiveOperationCount() -> Int {
        return activeOperations.count
    }
    
    func getCriticalOperations() -> [LoadingOperation] {
        return activeOperations.values.filter { $0.priority == .critical }
    }
    
    func getHighPriorityOperations() -> [LoadingOperation] {
        return activeOperations.values.filter { $0.priority == .high }
    }
    
    // MARK: - Convenience Methods
    
    func withLoading<T>(
        title: String,
        message: String? = nil,
        priority: LoadingPriority = .normal,
        operation: () async throws -> T
    ) async throws -> T {
        let id = startLoading(
            title: title,
            message: message,
            priority: priority
        )
        
        defer {
            completeLoading(id: id)
        }
        
        do {
            let result = try await operation()
            completeLoading(id: id, result: .success)
            return result
        } catch {
            completeLoading(id: id, result: .failure(error))
            throw error
        }
    }
    
    func withProgressLoading<T>(
        title: String,
        message: String? = nil,
        priority: LoadingPriority = .normal,
        estimatedDuration: TimeInterval? = nil,
        operation: (String) async throws -> T
    ) async throws -> T {
        let id = startLoading(
            title: title,
            message: message,
            priority: priority,
            showProgress: true,
            estimatedDuration: estimatedDuration
        )
        
        defer {
            completeLoading(id: id)
        }
        
        do {
            let result = try await operation(id)
            completeLoading(id: id, result: .success)
            return result
        } catch {
            completeLoading(id: id, result: .failure(error))
            throw error
        }
    }
    
    // MARK: - History Management
    
    private func addToHistory(_ operation: LoadingOperation) {
        let entry = LoadingHistoryEntry(
            operation: operation,
            timestamp: Date()
        )
        
        loadingHistory.insert(entry, at: 0)
        
        if loadingHistory.count > maxHistoryEntries {
            loadingHistory = Array(loadingHistory.prefix(maxHistoryEntries))
        }
    }
    
    func clearHistory() {
        loadingHistory.removeAll()
    }
    
    // MARK: - Logging
    
    private func logLoadingEvent(_ event: LoadingEvent, operation: LoadingOperation) {
        let duration = operation.endTime?.timeIntervalSince(operation.startTime)
        let durationString = duration.map { String(format: "%.2fs", $0) } ?? "ongoing"
        
        let logMessage = """
        [LOADING] \(event.rawValue.uppercased()): \(operation.title)
        ID: \(operation.id)
        Priority: \(operation.priority.rawValue)
        Duration: \(durationString)
        Message: \(operation.message ?? "None")
        Progress: \(operation.showProgress ? String(format: "%.1f%%", operation.progress * 100) : "N/A")
        """
        
        print(logMessage)
    }
    
    // MARK: - Statistics
    
    func getLoadingStatistics() -> LoadingStatistics {
        let totalOperations = loadingHistory.count
        let successfulOperations = loadingHistory.filter {
            if case .success = $0.operation.result {
                return true
            }
            return false
        }.count
        
        let failedOperations = loadingHistory.filter {
            if case .failure = $0.operation.result {
                return true
            }
            return false
        }.count
        
        let cancelledOperations = loadingHistory.filter {
            if case .cancelled = $0.operation.result {
                return true
            }
            return false
        }.count
        
        let averageDuration = loadingHistory.compactMap { entry in
            entry.operation.duration
        }.reduce(0, +) / Double(max(1, loadingHistory.count))
        
        return LoadingStatistics(
            totalOperations: totalOperations,
            activeOperations: activeOperations.count,
            successfulOperations: successfulOperations,
            failedOperations: failedOperations,
            cancelledOperations: cancelledOperations,
            averageDuration: averageDuration,
            successRate: totalOperations > 0 ? Double(successfulOperations) / Double(totalOperations) : 0
        )
    }
}

// MARK: - Supporting Types

struct LoadingOperation {
    let id: String
    let title: String
    var message: String?
    let priority: LoadingPriority
    let showProgress: Bool
    let estimatedDuration: TimeInterval?
    let isCancellable: Bool
    let startTime: Date
    var lastUpdated: Date
    var endTime: Date?
    var progress: Double = 0.0
    var currentStep: String?
    var result: LoadingResult?
    
    init(
        id: String,
        title: String,
        message: String? = nil,
        priority: LoadingPriority = .normal,
        showProgress: Bool = false,
        estimatedDuration: TimeInterval? = nil,
        isCancellable: Bool = false,
        startTime: Date
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.priority = priority
        self.showProgress = showProgress
        self.estimatedDuration = estimatedDuration
        self.isCancellable = isCancellable
        self.startTime = startTime
        self.lastUpdated = startTime
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isCompleted: Bool {
        return endTime != nil
    }
    
    var estimatedProgress: Double {
        guard let estimatedDuration = estimatedDuration else { return progress }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let estimatedProgress = elapsed / estimatedDuration
        
        return min(max(estimatedProgress, progress), 0.95) // Cap at 95% until actually complete
    }
}

enum LoadingPriority: String, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low:
            return "低"
        case .normal:
            return "通常"
        case .high:
            return "高"
        case .critical:
            return "緊急"
        }
    }
}

enum LoadingResult {
    case success
    case failure(Error)
    case cancelled(reason: String)
    
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var displayName: String {
        switch self {
        case .success:
            return "成功"
        case .failure:
            return "失敗"
        case .cancelled:
            return "キャンセル"
        }
    }
}

enum GlobalLoadingState {
    case idle
    case loading
    case busy
    case critical
    
    var displayName: String {
        switch self {
        case .idle:
            return "待機中"
        case .loading:
            return "読み込み中"
        case .busy:
            return "処理中"
        case .critical:
            return "重要な処理中"
        }
    }
}

enum LoadingEvent: String {
    case started = "started"
    case updated = "updated"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct LoadingHistoryEntry {
    let id = UUID()
    let operation: LoadingOperation
    let timestamp: Date
}

struct LoadingStatistics {
    let totalOperations: Int
    let activeOperations: Int
    let successfulOperations: Int
    let failedOperations: Int
    let cancelledOperations: Int
    let averageDuration: TimeInterval
    let successRate: Double
}

// MARK: - SwiftUI Integration

extension LoadingStateManager {
    func loadingBinding(for id: String) -> Binding<Bool> {
        return Binding(
            get: { self.isLoading(id: id) },
            set: { isLoading in
                if !isLoading && self.isLoading(id: id) {
                    self.completeLoading(id: id)
                }
            }
        )
    }
    
    func progressBinding(for id: String) -> Binding<Double> {
        return Binding(
            get: { self.getLoadingOperation(id: id)?.progress ?? 0.0 },
            set: { progress in
                self.updateLoading(id: id, progress: progress)
            }
        )
    }
}
