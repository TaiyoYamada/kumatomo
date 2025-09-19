import XCTest
import Combine
@testable import kumatomo

@MainActor
class ErrorHandlingTests: XCTestCase {
    
    var errorManager: ErrorManager!
    var networkMonitor: NetworkMonitor!
    var loadingStateManager: LoadingStateManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        errorManager = ErrorManager.shared
        networkMonitor = NetworkMonitor.shared
        loadingStateManager = LoadingStateManager.shared
        cancellables = Set<AnyCancellable>()
        
        // Clear any existing state
        errorManager.dismissError()
        errorManager.clearHistory()
        loadingStateManager.cancelAllLoading()
        loadingStateManager.clearHistory()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - Error Manager Tests
    
    func testErrorManagerHandlesAPIError() {
        // Given
        let apiError = APIError.serverError(message: "Test server error")
        let context = "Test context"
        
        // When
        errorManager.handleError(apiError, context: context)
        
        // Then
        XCTAssertTrue(errorManager.isShowingError)
        XCTAssertNotNil(errorManager.currentError)
        XCTAssertEqual(errorManager.currentError?.context, context)
        XCTAssertEqual(errorManager.errorHistory.count, 1)
    }
    
    func testErrorManagerHandlesNetworkError() {
        // Given
        let networkError = URLError(.notConnectedToInternet)
        
        // When
        errorManager.handleError(networkError, context: "Network test")
        
        // Then
        XCTAssertTrue(errorManager.isShowingError)
        XCTAssertNotNil(errorManager.currentError)
        XCTAssertEqual(errorManager.currentError?.errorType, .network)
    }
    
    func testErrorManagerDismissesError() {
        // Given
        let error = APIError.timeout
        errorManager.handleError(error)
        
        // When
        errorManager.dismissError()
        
        // Then
        XCTAssertFalse(errorManager.isShowingError)
        XCTAssertNil(errorManager.currentError)
    }
    
    func testErrorManagerClearsHistory() {
        // Given
        errorManager.handleError(APIError.timeout)
        errorManager.handleError(APIError.unauthorized)
        XCTAssertEqual(errorManager.errorHistory.count, 2)
        
        // When
        errorManager.clearHistory()
        
        // Then
        XCTAssertEqual(errorManager.errorHistory.count, 0)
    }
    
    func testErrorManagerStatistics() {
        // Given
        errorManager.handleError(APIError.networkError(URLError(.notConnectedToInternet)))
        errorManager.handleError(APIError.serverError(message: "Server error"))
        errorManager.handleError(APIError.validationError("Validation error"))
        
        // When
        let statistics = errorManager.getErrorStatistics()
        
        // Then
        XCTAssertEqual(statistics.totalErrors, 3)
        XCTAssertEqual(statistics.networkErrors, 1)
        XCTAssertEqual(statistics.apiErrors, 2)
        XCTAssertEqual(statistics.validationErrors, 1)
        XCTAssertNotNil(statistics.lastError)
    }
    
    // MARK: - Network Monitor Tests
    
    func testNetworkMonitorDetectsNetworkError() {
        // Given
        let urlError = URLError(.notConnectedToInternet)
        
        // When
        let isNetworkError = networkMonitor.isNetworkError(urlError)
        
        // Then
        XCTAssertTrue(isNetworkError)
    }
    
    func testNetworkMonitorGetErrorMessage() {
        // Given
        let urlError = URLError(.timedOut)
        
        // When
        let message = networkMonitor.getNetworkErrorMessage(urlError)
        
        // Then
        XCTAssertEqual(message, "接続がタイムアウトしました")
    }
    
    func testNetworkMonitorShouldRetryLogic() {
        // Given
        let retryableError = URLError(.timedOut)
        let nonRetryableError = URLError(.notConnectedToInternet)
        
        // When & Then
        XCTAssertTrue(networkMonitor.shouldRetryNetworkRequest(retryableError))
        XCTAssertFalse(networkMonitor.shouldRetryNetworkRequest(nonRetryableError))
    }
    
    func testNetworkMonitorRetryDelay() {
        // Given
        let error = URLError(.timedOut)
        
        // When
        let delay1 = networkMonitor.getRetryDelay(for: error, attempt: 1)
        let delay2 = networkMonitor.getRetryDelay(for: error, attempt: 2)
        let delay3 = networkMonitor.getRetryDelay(for: error, attempt: 3)
        
        // Then
        XCTAssertGreaterThan(delay1, 0)
        XCTAssertGreaterThan(delay2, delay1)
        XCTAssertGreaterThan(delay3, delay2)
        XCTAssertLessThanOrEqual(delay3, 30.0) // Max delay
    }
    
    func testNetworkDiagnostics() async {
        // When
        let diagnostics = await networkMonitor.performNetworkDiagnostics()
        
        // Then
        XCTAssertNotNil(diagnostics)
        XCTAssertGreaterThan(diagnostics.totalDiagnosticTime, 0)
        XCTAssertNotNil(diagnostics.connectivityTest)
        XCTAssertNotNil(diagnostics.dnsTest)
        XCTAssertNotNil(diagnostics.serverTest)
    }
    
    // MARK: - Loading State Manager Tests
    
    func testLoadingStateManagerStartsLoading() {
        // Given
        let title = "Test Loading"
        let message = "Loading test data"
        
        // When
        let id = loadingStateManager.startLoading(
            title: title,
            message: message,
            priority: .normal
        )
        
        // Then
        XCTAssertTrue(loadingStateManager.isLoading(id: id))
        XCTAssertTrue(loadingStateManager.hasActiveOperations())
        XCTAssertEqual(loadingStateManager.getActiveOperationCount(), 1)
        
        let operation = loadingStateManager.getLoadingOperation(id: id)
        XCTAssertNotNil(operation)
        XCTAssertEqual(operation?.title, title)
        XCTAssertEqual(operation?.message, message)
    }
    
    func testLoadingStateManagerUpdatesProgress() {
        // Given
        let id = loadingStateManager.startLoading(
            title: "Test",
            showProgress: true
        )
        
        // When
        loadingStateManager.updateLoading(id: id, progress: 0.5)
        
        // Then
        let operation = loadingStateManager.getLoadingOperation(id: id)
        XCTAssertEqual(operation?.progress, 0.5)
    }
    
    func testLoadingStateManagerCompletesLoading() {
        // Given
        let id = loadingStateManager.startLoading(title: "Test")
        
        // When
        loadingStateManager.completeLoading(id: id, result: .success)
        
        // Then
        XCTAssertFalse(loadingStateManager.isLoading(id: id))
        XCTAssertEqual(loadingStateManager.loadingHistory.count, 1)
        
        let historyEntry = loadingStateManager.loadingHistory.first
        XCTAssertNotNil(historyEntry)
        XCTAssertTrue(historyEntry?.operation.result?.isSuccess ?? false)
    }
    
    func testLoadingStateManagerCancelsLoading() {
        // Given
        let id = loadingStateManager.startLoading(
            title: "Test",
            isCancellable: true
        )
        
        // When
        loadingStateManager.cancelLoading(id: id, reason: "Test cancellation")
        
        // Then
        XCTAssertFalse(loadingStateManager.isLoading(id: id))
        XCTAssertEqual(loadingStateManager.loadingHistory.count, 1)
        
        let historyEntry = loadingStateManager.loadingHistory.first
        if case .cancelled(let reason) = historyEntry?.operation.result {
            XCTAssertEqual(reason, "Test cancellation")
        } else {
            XCTFail("Expected cancelled result")
        }
    }
    
    func testLoadingStateManagerWithLoadingWrapper() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Loading wrapper completes")
        var operationExecuted = false
        
        // When
        let result = try await loadingStateManager.withLoading(
            title: "Test Operation",
            message: "Testing wrapper"
        ) {
            operationExecuted = true
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            expectation.fulfill()
            return "Success"
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(operationExecuted)
        XCTAssertEqual(result, "Success")
        XCTAssertFalse(loadingStateManager.hasActiveOperations())
    }
    
    func testLoadingStateManagerWithProgressWrapper() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Progress loading completes")
        var progressUpdated = false
        
        // When
        let result = try await loadingStateManager.withProgressLoading(
            title: "Progress Test",
            estimatedDuration: 1.0
        ) { operationId in
            loadingStateManager.updateLoading(id: operationId, progress: 0.5)
            progressUpdated = true
            expectation.fulfill()
            return "Progress Success"
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(progressUpdated)
        XCTAssertEqual(result, "Progress Success")
    }
    
    func testLoadingStateManagerStatistics() {
        // Given
        let id1 = loadingStateManager.startLoading(title: "Test 1")
        let id2 = loadingStateManager.startLoading(title: "Test 2")
        let id3 = loadingStateManager.startLoading(title: "Test 3")
        
        loadingStateManager.completeLoading(id: id1, result: .success)
        loadingStateManager.completeLoading(id: id2, result: .failure(APIError.timeout))
        loadingStateManager.cancelLoading(id: id3)
        
        // When
        let statistics = loadingStateManager.getLoadingStatistics()
        
        // Then
        XCTAssertEqual(statistics.totalOperations, 3)
        XCTAssertEqual(statistics.successfulOperations, 1)
        XCTAssertEqual(statistics.failedOperations, 1)
        XCTAssertEqual(statistics.cancelledOperations, 1)
        XCTAssertEqual(statistics.successRate, 1.0/3.0, accuracy: 0.01)
    }
    
    // MARK: - Integration Tests
    
    func testErrorAndLoadingIntegration() async {
        // Given
        let loadingId = loadingStateManager.startLoading(
            title: "API Request",
            message: "Fetching data"
        )
        
        // Simulate network error
        let networkError = URLError(.timedOut)
        
        // When
        errorManager.handleError(networkError, context: "API request failed")
        loadingStateManager.completeLoading(
            id: loadingId,
            result: .failure(networkError)
        )
        
        // Then
        XCTAssertTrue(errorManager.isShowingError)
        XCTAssertFalse(loadingStateManager.isLoading(id: loadingId))
        
        let loadingHistory = loadingStateManager.loadingHistory.first
        XCTAssertNotNil(loadingHistory)
        XCTAssertFalse(loadingHistory?.operation.result?.isSuccess ?? true)
    }
    
    func testRetryMechanismIntegration() async throws {
        // Given
        var attemptCount = 0
        let maxAttempts = 3
        let expectation = XCTestExpectation(description: "Retry mechanism completes")
        
        // When
        do {
            _ = try await loadingStateManager.withLoading(
                title: "Retry Test"
            ) {
                attemptCount += 1
                if attemptCount < maxAttempts {
                    throw APIError.timeout
                }
                expectation.fulfill()
                return "Success after retries"
            }
        } catch {
            // Handle expected error for failed attempts
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(attemptCount, maxAttempts)
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingPerformance() {
        measure {
            for i in 0..<1000 {
                let error = APIError.serverError(message: "Error \(i)")
                errorManager.handleError(error, context: "Performance test")
            }
        }
    }
    
    func testLoadingStatePerformance() {
        measure {
            var operations: [String] = []
            
            // Start many operations
            for i in 0..<100 {
                let id = loadingStateManager.startLoading(title: "Operation \(i)")
                operations.append(id)
            }
            
            // Complete them all
            for id in operations {
                loadingStateManager.completeLoading(id: id, result: .success)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testErrorManagerWithNilError() {
        // This test ensures the error manager handles unexpected nil cases gracefully
        // In practice, this might not be possible due to Swift's type system,
        // but it's good to test error boundaries
        
        let unknownError = NSError(domain: "TestDomain", code: -1, userInfo: nil)
        errorManager.handleError(unknownError)
        
        XCTAssertTrue(errorManager.isShowingError)
        XCTAssertNotNil(errorManager.currentError)
    }
    
    func testLoadingManagerWithDuplicateIds() {
        // Given
        let id = "duplicate-id"
        
        // When
        loadingStateManager.startLoading(id: id, title: "First")
        loadingStateManager.startLoading(id: id, title: "Second") // Should overwrite
        
        // Then
        let operation = loadingStateManager.getLoadingOperation(id: id)
        XCTAssertEqual(operation?.title, "Second")
        XCTAssertEqual(loadingStateManager.getActiveOperationCount(), 1)
    }
    
    func testNetworkMonitorWithInvalidError() {
        // Given
        let customError = NSError(domain: "CustomDomain", code: 999, userInfo: nil)
        
        // When
        let isNetworkError = networkMonitor.isNetworkError(customError)
        let message = networkMonitor.getNetworkErrorMessage(customError)
        
        // Then
        XCTAssertFalse(isNetworkError)
        XCTAssertEqual(message, "ネットワークエラーが発生しました")
    }
}