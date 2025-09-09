import Foundation
import Combine

// MARK: - Retry Manager for Profile Operations

@MainActor
class RetryManager: ObservableObject {
    static let shared = RetryManager()
    
    @Published var activeRetries: [String: RetryOperation] = [:]
    @Published var retryHistory: [RetryHistoryEntry] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var cancellationTokens: [String: CancellationToken] = [:]
    private let maxHistoryEntries = 100
    private let progressTracker = ProgressTracker.shared
    
    private init() {}
    
    // MARK: - Retry Operation Management
    
    /// Executes an operation with automatic retry logic and progress tracking
    func executeWithRetry<T>(
        operation: @escaping (CancellationToken) async throws -> T,
        retryPolicy: RetryPolicy = .default,
        operationId: String = UUID().uuidString,
        progressTitle: String? = nil
    ) async throws -> T {
        var retryOperation = RetryOperation(
            id: operationId,
            policy: retryPolicy,
            startTime: Date()
        )
        
        let cancellationToken = CancellationToken()
        cancellationTokens[operationId] = cancellationToken
        activeRetries[operationId] = retryOperation
        
        // Start progress tracking if title provided
        var progressId: String?
        if let title = progressTitle {
            progressId = progressTracker.startOperation(
                id: operationId,
                title: title,
                type: .updateProfile,
                estimatedDuration: TimeInterval(retryPolicy.maxAttempts) * retryPolicy.baseDelay,
                isCancellable: true
            )
        }
        
        defer {
            activeRetries.removeValue(forKey: operationId)
            cancellationTokens.removeValue(forKey: operationId)
            
            if let progressId = progressId {
                if cancellationToken.isCancelled {
                    progressTracker.cancelOperation(id: progressId, reason: "Retry operation cancelled")
                }
            }
        }
        
        var lastError: Error?
        
        for attempt in 0..<retryPolicy.maxAttempts {
            do {
                // Check for cancellation before each attempt
                try cancellationToken.throwIfCancelled()
                
                // Update progress
                if let progressId = progressId {
                    let progress = Double(attempt) / Double(retryPolicy.maxAttempts)
                    progressTracker.updateProgress(
                        id: progressId,
                        progress: progress,
                        message: attempt == 0 ? "実行中..." : "再試行中... (\(attempt + 1)/\(retryPolicy.maxAttempts))",
                        currentStep: "\(attempt + 1)/\(retryPolicy.maxAttempts)"
                    )
                }
                
                let result = try await operation(cancellationToken)
                
                // Success - log and return
                logRetrySuccess(operationId: operationId, attempt: attempt)
                
                if let progressId = progressId {
                    progressTracker.completeSuccessfully(id: progressId, result: result)
                }
                
                return result
                
            } catch {
                // Check if error is due to cancellation
                if cancellationToken.isCancelled {
                    throw ProgressError.operationCancelled(reason: cancellationToken.cancellationReason ?? "Operation cancelled")
                }
                
                lastError = error
                retryOperation.attempts = attempt + 1
                retryOperation.lastError = error
                
                // Check if we should retry
                guard attempt < retryPolicy.maxAttempts - 1 else {
                    break
                }
                
                guard shouldRetry(error: error, policy: retryPolicy, attempt: attempt) else {
                    break
                }
                
                // Calculate delay and wait
                let delay = calculateDelay(
                    error: error,
                    policy: retryPolicy,
                    attempt: attempt
                )
                
                logRetryAttempt(
                    operationId: operationId,
                    attempt: attempt,
                    error: error,
                    delay: delay
                )
                
                // Update progress with retry delay
                if let progressId = progressId {
                    progressTracker.updateProgress(
                        id: progressId,
                        progress: Double(attempt + 1) / Double(retryPolicy.maxAttempts),
                        message: "再試行まで \(Int(delay))秒 待機中...",
                        currentStep: "\(attempt + 1)/\(retryPolicy.maxAttempts)"
                    )
                }
                
                // Wait with cancellation check
                try await waitWithCancellation(delay: delay, cancellationToken: cancellationToken)
            }
        }
        
        // All retries failed
        logRetryFailure(operationId: operationId, finalError: lastError!)
        
        if let progressId = progressId {
            progressTracker.completeWithFailure(id: progressId, error: lastError!)
        }
        
        throw lastError!
    }
    
    /// Cancels an active retry operation
    func cancelRetry(operationId: String, reason: String = "User cancelled") {
        if let cancellationToken = cancellationTokens[operationId] {
            cancellationToken.cancel(reason: reason)
        }
        activeRetries.removeValue(forKey: operationId)
        cancellationTokens.removeValue(forKey: operationId)
        
        print("🚫 Cancelled retry operation: \(operationId)")
    }
    
    /// Cancels all active retry operations
    func cancelAllRetries(reason: String = "Bulk cancellation") {
        for (_, cancellationToken) in cancellationTokens {
            cancellationToken.cancel(reason: reason)
        }
        
        activeRetries.removeAll()
        cancellationTokens.removeAll()
        
        print("🚫 Cancelled all retry operations")
    }
    
    /// Checks if an operation can be cancelled
    func canCancelRetry(operationId: String) -> Bool {
        return cancellationTokens[operationId] != nil
    }
    
    // MARK: - Retry Logic
    
    private func shouldRetry(error: Error, policy: RetryPolicy, attempt: Int) -> Bool {
        // Check if error is retryable
        if let profileError = error as? ProfileError {
            return profileError.shouldAutoRetry
        }
        
        // Check policy-specific conditions
        switch policy.strategy {
        case .exponentialBackoff:
            return isRetryableError(error)
        case .fixedInterval:
            return isRetryableError(error)
        case .immediate:
            return isRetryableError(error)
        case .custom(let shouldRetryBlock, _):
            return shouldRetryBlock(error, attempt)
        }
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        if let profileError = error as? ProfileError {
            return profileError.shouldAutoRetry
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    private func calculateDelay(error: Error, policy: RetryPolicy, attempt: Int) -> TimeInterval {
        let baseDelay: TimeInterval
        
        // Get error-specific delay if available
        if let profileError = error as? ProfileError {
            baseDelay = profileError.retryDelay
        } else {
            baseDelay = policy.baseDelay
        }
        
        switch policy.strategy {
        case .exponentialBackoff(let multiplier, let maxDelay):
            let delay = baseDelay * pow(multiplier, Double(attempt))
            return min(delay, maxDelay)
            
        case .fixedInterval:
            return baseDelay
            
        case .immediate:
            return 0
            
        case .custom(_, let delayCalculator):
            return delayCalculator?(error, attempt) ?? baseDelay
        }
    }
    
    // MARK: - Logging and History
    
    private func logRetryAttempt(operationId: String, attempt: Int, error: Error, delay: TimeInterval) {
        let entry = RetryHistoryEntry(
            operationId: operationId,
            attempt: attempt,
            error: error,
            timestamp: Date(),
            outcome: .retrying(delay: delay)
        )
        
        addToHistory(entry)
        
        print("🔄 Retry attempt \(attempt + 1) for operation \(operationId): \(error.localizedDescription), waiting \(delay)s")
    }
    
    private func logRetrySuccess(operationId: String, attempt: Int) {
        let entry = RetryHistoryEntry(
            operationId: operationId,
            attempt: attempt,
            error: nil,
            timestamp: Date(),
            outcome: .success
        )
        
        addToHistory(entry)
        
        print("✅ Operation \(operationId) succeeded after \(attempt + 1) attempts")
    }
    
    private func logRetryFailure(operationId: String, finalError: Error) {
        let entry = RetryHistoryEntry(
            operationId: operationId,
            attempt: -1,
            error: finalError,
            timestamp: Date(),
            outcome: .failed
        )
        
        addToHistory(entry)
        
        print("❌ Operation \(operationId) failed after all retry attempts: \(finalError.localizedDescription)")
    }
    
    private func addToHistory(_ entry: RetryHistoryEntry) {
        retryHistory.insert(entry, at: 0)
        
        if retryHistory.count > maxHistoryEntries {
            retryHistory = Array(retryHistory.prefix(maxHistoryEntries))
        }
    }
    
    // MARK: - Statistics
    
    func getRetryStatistics() -> RetryStatistics {
        let totalOperations = Set(retryHistory.map { $0.operationId }).count
        let successfulOperations = Set(retryHistory.filter { $0.outcome == .success }.map { $0.operationId }).count
        let failedOperations = Set(retryHistory.filter { $0.outcome == .failed }.map { $0.operationId }).count
        
        let totalAttempts = retryHistory.count
        let averageAttempts = totalOperations > 0 ? Double(totalAttempts) / Double(totalOperations) : 0
        
        return RetryStatistics(
            totalOperations: totalOperations,
            successfulOperations: successfulOperations,
            failedOperations: failedOperations,
            averageAttempts: averageAttempts,
            successRate: totalOperations > 0 ? Double(successfulOperations) / Double(totalOperations) : 0
        )
    }
    
    func clearHistory() {
        retryHistory.removeAll()
    }
    
    // MARK: - Private Helper Methods
    
    /// Waits for a delay while checking for cancellation
    private func waitWithCancellation(delay: TimeInterval, cancellationToken: CancellationToken) async throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(delay)
        
        while Date() < endTime {
            try cancellationToken.throwIfCancelled()
            
            // Sleep in small increments to allow for responsive cancellation
            let remainingTime = endTime.timeIntervalSinceNow
            let sleepTime = min(0.1, remainingTime) // Check every 100ms
            
            if sleepTime > 0 {
                try await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
            }
        }
    }
}

// MARK: - Supporting Types

struct RetryOperation {
    let id: String
    let policy: RetryPolicy
    let startTime: Date
    var attempts: Int = 0
    var lastError: Error?
}

struct RetryPolicy {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let strategy: RetryStrategy
    
    static let `default` = RetryPolicy(
        maxAttempts: 3,
        baseDelay: 2.0,
        strategy: .exponentialBackoff(multiplier: 2.0, maxDelay: 30.0)
    )
    
    static let aggressive = RetryPolicy(
        maxAttempts: 5,
        baseDelay: 1.0,
        strategy: .exponentialBackoff(multiplier: 1.5, maxDelay: 15.0)
    )
    
    static let conservative = RetryPolicy(
        maxAttempts: 2,
        baseDelay: 5.0,
        strategy: .fixedInterval
    )
    
    static let immediate = RetryPolicy(
        maxAttempts: 3,
        baseDelay: 0.0,
        strategy: .immediate
    )
}

enum RetryStrategy {
    case exponentialBackoff(multiplier: Double, maxDelay: TimeInterval)
    case fixedInterval
    case immediate
    case custom(
        shouldRetry: (Error, Int) -> Bool,
        delayCalculator: ((Error, Int) -> TimeInterval)?
    )
}

struct RetryHistoryEntry {
    let id = UUID()
    let operationId: String
    let attempt: Int
    let error: Error?
    let timestamp: Date
    let outcome: RetryOutcome
}

enum RetryOutcome: Equatable {
    case retrying(delay: TimeInterval)
    case success
    case failed
    
    static func == (lhs: RetryOutcome, rhs: RetryOutcome) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success), (.failed, .failed):
            return true
        case (.retrying(let delay1), .retrying(let delay2)):
            return delay1 == delay2
        default:
            return false
        }
    }
}

struct RetryStatistics {
    let totalOperations: Int
    let successfulOperations: Int
    let failedOperations: Int
    let averageAttempts: Double
    let successRate: Double
}

// MARK: - Convenience Extensions

extension RetryManager {
    /// Convenience method for profile operations
    func executeProfileOperation<T>(
        _ operation: @escaping (CancellationToken) async throws -> T,
        operationName: String = "ProfileOperation",
        showProgress: Bool = true
    ) async throws -> T {
        return try await executeWithRetry(
            operation: operation,
            retryPolicy: .default,
            operationId: "\(operationName)_\(UUID().uuidString.prefix(8))",
            progressTitle: showProgress ? operationName : nil
        )
    }
    
    /// Convenience method for image upload operations
    func executeImageUpload<T>(
        _ operation: @escaping (CancellationToken) async throws -> T,
        operationName: String = "ImageUpload",
        showProgress: Bool = true
    ) async throws -> T {
        return try await executeWithRetry(
            operation: operation,
            retryPolicy: .aggressive,
            operationId: "\(operationName)_\(UUID().uuidString.prefix(8))",
            progressTitle: showProgress ? operationName : nil
        )
    }
    
    /// Convenience method for network operations
    func executeNetworkOperation<T>(
        _ operation: @escaping (CancellationToken) async throws -> T,
        operationName: String = "NetworkOperation",
        showProgress: Bool = false
    ) async throws -> T {
        return try await executeWithRetry(
            operation: operation,
            retryPolicy: .conservative,
            operationId: "\(operationName)_\(UUID().uuidString.prefix(8))",
            progressTitle: showProgress ? operationName : nil
        )
    }
    
    /// Legacy method for operations that don't need cancellation support
    func executeWithRetryLegacy<T>(
        operation: @escaping () async throws -> T,
        retryPolicy: RetryPolicy = .default,
        operationId: String = UUID().uuidString
    ) async throws -> T {
        return try await executeWithRetry(
            operation: { _ in try await operation() },
            retryPolicy: retryPolicy,
            operationId: operationId
        )
    }
}