import XCTest
import Combine
@testable import kumatomo

@MainActor
class EnhancedRetryManagerTests: XCTestCase {
    
    var retryManager: RetryManager!
    var progressTracker: ProgressTracker!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        retryManager = RetryManager.shared
        progressTracker = ProgressTracker.shared
        cancellables = Set<AnyCancellable>()
        
        // Clear any existing state
        retryManager.cancelAllRetries()
        retryManager.clearHistory()
        progressTracker.cancelAllOperations()
        progressTracker.clearHistory()
    }
    
    override func tearDown() {
        retryManager.cancelAllRetries()
        retryManager.clearHistory()
        progressTracker.cancelAllOperations()
        progressTracker.clearHistory()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Basic Retry Tests with Cancellation
    
    func testSuccessfulOperationWithCancellation() async throws {
        // Given
        var callCount = 0
        let operation: (CancellationToken) async throws -> String = { token in
            callCount += 1
            try token.throwIfCancelled()
            return "Success"
        }
        
        // When
        let result = try await retryManager.executeWithRetry(
            operation: operation,
            retryPolicy: .default,
            operationId: "test-success"
        )
        
        // Then
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(retryManager.activeRetries.count, 0)
    }
    
    func testRetryWithCancellation() async throws {
        // Given
        var callCount = 0
        let operation: (CancellationToken) async throws -> String = { token in
            callCount += 1
            try token.throwIfCancelled()
            
            if callCount < 3 {
                throw TestError.temporaryFailure
            }
            return "Success after retries"
        }
        
        // When
        let result = try await retryManager.executeWithRetry(
            operation: operation,
            retryPolicy: RetryPolicy(maxAttempts: 3, baseDelay: 0.1, strategy: .fixedInterval),
            operationId: "test-retry"
        )
        
        // Then
        XCTAssertEqual(result, "Success after retries")
        XCTAssertEqual(callCount, 3)
    }
    
    func testOperationCancellation() async {
        // Given
        let expectation = XCTestExpectation(description: "Operation cancelled")
        let operationId = "test-cancel"
        
        let operation: (CancellationToken) async throws -> String = { token in
            // Simulate long-running operation
            for _ in 0..<100 {
                try token.throwIfCancelled()
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            return "Should not reach here"
        }
        
        // When
        Task {
            do {
                _ = try await retryManager.executeWithRetry(
                    operation: operation,
                    retryPolicy: .default,
                    operationId: operationId
                )
                XCTFail("Operation should have been cancelled")
            } catch {
                if case ProgressError.operationCancelled = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected cancellation error, got: \(error)")
                }
            }
        }
        
        // Cancel after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.retryManager.cancelRetry(operationId: operationId, reason: "Test cancellation")
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testCancelAllRetries() async {
        // Given
        let expectation1 = XCTestExpectation(description: "Operation 1 cancelled")
        let expectation2 = XCTestExpectation(description: "Operation 2 cancelled")
        
        let longOperation: (CancellationToken) async throws -> String = { token in
            for _ in 0..<100 {
                try token.throwIfCancelled()
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            return "Should not reach here"
        }
        
        // When
        Task {
            do {
                _ = try await retryManager.executeWithRetry(
                    operation: longOperation,
                    operationId: "op1"
                )
                XCTFail("Operation 1 should have been cancelled")
            } catch {
                expectation1.fulfill()
            }
        }
        
        Task {
            do {
                _ = try await retryManager.executeWithRetry(
                    operation: longOperation,
                    operationId: "op2"
                )
                XCTFail("Operation 2 should have been cancelled")
            } catch {
                expectation2.fulfill()
            }
        }
        
        // Cancel all after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.retryManager.cancelAllRetries(reason: "Test bulk cancellation")
        }
        
        // Then
        await fulfillment(of: [expectation1, expectation2], timeout: 1.0)
    }
    
    // MARK: - Progress Tracking Integration Tests
    
    func testRetryWithProgressTracking() async throws {
        // Given
        var callCount = 0
        let operation: (CancellationToken) async throws -> String = { token in
            callCount += 1
            try token.throwIfCancelled()
            
            if callCount < 2 {
                throw TestError.temporaryFailure
            }
            return "Success"
        }
        
        // When
        let result = try await retryManager.executeWithRetry(
            operation: operation,
            retryPolicy: RetryPolicy(maxAttempts: 3, baseDelay: 0.1, strategy: .fixedInterval),
            operationId: "test-progress",
            progressTitle: "Test Operation with Progress"
        )
        
        // Then
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(callCount, 2)
        
        // Check that progress was tracked
        XCTAssertEqual(progressTracker.completedOperations.count, 1)
        XCTAssertTrue(progressTracker.completedOperations.first?.success ?? false)
    }
    
    func testRetryFailureWithProgressTracking() async {
        // Given
        let operation: (CancellationToken) async throws -> String = { token in
            try token.throwIfCancelled()
            throw TestError.permanentFailure
        }
        
        // When & Then
        do {
            _ = try await retryManager.executeWithRetry(
                operation: operation,
                retryPolicy: RetryPolicy(maxAttempts: 2, baseDelay: 0.1, strategy: .fixedInterval),
                operationId: "test-failure-progress",
                progressTitle: "Failing Operation"
            )
            XCTFail("Operation should have failed")
        } catch {
            // Check that progress was tracked for failure
            XCTAssertEqual(progressTracker.completedOperations.count, 1)
            XCTAssertFalse(progressTracker.completedOperations.first?.success ?? true)
        }
    }
    
    // MARK: - Convenience Method Tests
    
    func testExecuteProfileOperation() async throws {
        // Given
        let operation: (CancellationToken) async throws -> User = { token in
            try token.throwIfCancelled()
            return createTestUser()
        }
        
        // When
        let result = try await retryManager.executeProfileOperation(
            operation,
            operationName: "CreateProfile",
            showProgress: true
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(progressTracker.completedOperations.count, 1)
    }
    
    func testExecuteImageUpload() async throws {
        // Given
        let operation: (CancellationToken) async throws -> String = { token in
            try token.throwIfCancelled()
            // Simulate image upload
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            return "https://example.com/image.jpg"
        }
        
        // When
        let result = try await retryManager.executeImageUpload(
            operation,
            operationName: "UploadProfileImage",
            showProgress: true
        )
        
        // Then
        XCTAssertEqual(result, "https://example.com/image.jpg")
        XCTAssertEqual(progressTracker.completedOperations.count, 1)
    }
    
    func testExecuteNetworkOperation() async throws {
        // Given
        let operation: (CancellationToken) async throws -> [String: Any] = { token in
            try token.throwIfCancelled()
            return ["status": "success", "data": "test"]
        }
        
        // When
        let result = try await retryManager.executeNetworkOperation(
            operation,
            operationName: "FetchData",
            showProgress: false
        )
        
        // Then
        XCTAssertNotNil(result["status"])
        // No progress tracking for network operations by default
        XCTAssertEqual(progressTracker.completedOperations.count, 0)
    }
    
    func testLegacyMethod() async throws {
        // Given
        let operation: () async throws -> String = {
            return "Legacy success"
        }
        
        // When
        let result = try await retryManager.executeWithRetryLegacy(
            operation: operation,
            retryPolicy: .default
        )
        
        // Then
        XCTAssertEqual(result, "Legacy success")
    }
    
    // MARK: - Cancellation Management Tests
    
    func testCanCancelRetry() {
        // Given
        let operationId = "test-can-cancel"
        
        Task {
            do {
                _ = try await retryManager.executeWithRetry(
                    operation: { token in
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        return "Should not complete"
                    },
                    operationId: operationId
                )
            } catch {
                // Expected to be cancelled
            }
        }
        
        // When & Then
        let expectation = XCTestExpectation(description: "Can cancel check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.retryManager.canCancelRetry(operationId: operationId))
            self.retryManager.cancelRetry(operationId: operationId)
            
            // After cancellation, should not be cancellable anymore
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertFalse(self.retryManager.canCancelRetry(operationId: operationId))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Wait with Cancellation Tests
    
    func testWaitWithCancellationNormal() async throws {
        // Given
        let token = CancellationToken()
        let startTime = Date()
        
        // When
        // Use reflection or make the method public for testing
        // For now, we'll test indirectly through retry mechanism
        
        let operation: (CancellationToken) async throws -> String = { token in
            throw TestError.temporaryFailure
        }
        
        do {
            _ = try await retryManager.executeWithRetry(
                operation: operation,
                retryPolicy: RetryPolicy(maxAttempts: 2, baseDelay: 0.2, strategy: .fixedInterval)
            )
        } catch {
            // Expected to fail after retries
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then - Should have waited for retry delay
        XCTAssertGreaterThan(elapsed, 0.15) // At least one retry delay
    }
    
    // MARK: - Error Handling Tests
    
    func testRetryableErrorHandling() async {
        // Given
        var callCount = 0
        let operation: (CancellationToken) async throws -> String = { token in
            callCount += 1
            try token.throwIfCancelled()
            
            if callCount == 1 {
                throw ProfileError.networkError(NSError(domain: "Test", code: 0))
            } else if callCount == 2 {
                throw ProfileError.connectionTimeout
            }
            
            return "Success after network errors"
        }
        
        // When
        let result = try await retryManager.executeWithRetry(
            operation: operation,
            retryPolicy: RetryPolicy(maxAttempts: 3, baseDelay: 0.1, strategy: .fixedInterval)
        )
        
        // Then
        XCTAssertEqual(result, "Success after network errors")
        XCTAssertEqual(callCount, 3)
    }
    
    func testNonRetryableErrorHandling() async {
        // Given
        let operation: (CancellationToken) async throws -> String = { token in
            try token.throwIfCancelled()
            throw ProfileError.unauthorized
        }
        
        // When & Then
        do {
            _ = try await retryManager.executeWithRetry(
                operation: operation,
                retryPolicy: RetryPolicy(maxAttempts: 3, baseDelay: 0.1, strategy: .fixedInterval)
            )
            XCTFail("Should not retry unauthorized error")
        } catch ProfileError.unauthorized {
            // Expected - should not retry
            XCTAssertEqual(retryManager.retryHistory.count, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser() -> User {
        return User(
            id: UUID().uuidString,
            name: "Test User",
            email: "test@example.com",
            username: "testuser",
            bio: "Test bio",
            city: "Test City",
            birthday: "1990-01-01",
            website: "https://test.com",
            profileImageURL: "https://test.com/profile.jpg",
            coverImageURL: "https://test.com/cover.jpg"
        )
    }
    
    // MARK: - Test Error Types
    
    enum TestError: Error {
        case temporaryFailure
        case permanentFailure
        case networkError
    }
}