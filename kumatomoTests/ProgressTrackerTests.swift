import XCTest
import Combine
@testable import kumatomo

@MainActor
class ProgressTrackerTests: XCTestCase {
    
    var progressTracker: ProgressTracker!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        progressTracker = ProgressTracker.shared
        cancellables = Set<AnyCancellable>()
        
        // Clear any existing operations
        progressTracker.cancelAllOperations()
        progressTracker.clearHistory()
    }
    
    override func tearDown() {
        progressTracker.cancelAllOperations()
        progressTracker.clearHistory()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Basic Operation Tests
    
    func testStartOperation() {
        // When
        let operationId = progressTracker.startOperation(
            title: "Test Operation",
            type: .createProfile,
            estimatedDuration: 10.0
        )
        
        // Then
        XCTAssertEqual(progressTracker.activeOperations.count, 1)
        XCTAssertNotNil(progressTracker.activeOperations[operationId])
        XCTAssertEqual(progressTracker.activeOperations[operationId]?.title, "Test Operation")
        XCTAssertEqual(progressTracker.activeOperations[operationId]?.type, .createProfile)
    }
    
    func testUpdateProgress() {
        // Given
        let operationId = progressTracker.startOperation(
            title: "Test Operation",
            type: .updateProfile
        )
        
        // When
        progressTracker.updateProgress(
            id: operationId,
            progress: 0.5,
            message: "Half complete",
            currentStep: "Step 2"
        )
        
        // Then
        XCTAssertEqual(progressTracker.getProgress(id: operationId), 0.5)
        XCTAssertEqual(progressTracker.getStatusMessage(id: operationId), "Half complete")
        XCTAssertEqual(progressTracker.activeOperations[operationId]?.currentStep, "Step 2")
    }
    
    func testCompleteOperation() {
        // Given
        let operationId = progressTracker.startOperation(
            title: "Test Operation",
            type: .createProfile
        )
        
        // When
        progressTracker.completeOperation(id: operationId, success: true, result: "Success")
        
        // Then
        XCTAssertEqual(progressTracker.activeOperations.count, 0)
        XCTAssertEqual(progressTracker.completedOperations.count, 1)
        XCTAssertTrue(progressTracker.completedOperations.first?.success ?? false)
    }
    
    func testCancelOperation() {
        // Given
        let operationId = progressTracker.startOperation(
            title: "Test Operation",
            type: .uploadProfileImage,
            isCancellable: true
        )
        
        // When
        progressTracker.cancelOperation(id: operationId, reason: "User cancelled")
        
        // Then
        XCTAssertEqual(progressTracker.activeOperations.count, 0)
        XCTAssertEqual(progressTracker.completedOperations.count, 1)
        XCTAssertFalse(progressTracker.completedOperations.first?.success ?? true)
    }
    
    func testCancelNonCancellableOperation() {
        // Given
        let operationId = progressTracker.startOperation(
            title: "Test Operation",
            type: .deleteProfile,
            isCancellable: false
        )
        
        // When
        progressTracker.cancelOperation(id: operationId)
        
        // Then - Operation should still be active since it's not cancellable
        XCTAssertEqual(progressTracker.activeOperations.count, 1)
        XCTAssertEqual(progressTracker.completedOperations.count, 0)
    }
    
    // MARK: - Progress Validation Tests
    
    func testProgressBounds() {
        // Given
        let operationId = progressTracker.startOperation(
            title: "Test Operation",
            type: .updateProfile
        )
        
        // When - Test progress bounds
        progressTracker.updateProgress(id: operationId, progress: -0.5) // Below 0
        XCTAssertEqual(progressTracker.getProgress(id: operationId), 0.0)
        
        progressTracker.updateProgress(id: operationId, progress: 1.5) // Above 1
        XCTAssertEqual(progressTracker.getProgress(id: operationId), 1.0)
        
        progressTracker.updateProgress(id: operationId, progress: 0.7) // Valid range
        XCTAssertEqual(progressTracker.getProgress(id: operationId), 0.7)
    }
    
    func testUpdateNonExistentOperation() {
        // When
        progressTracker.updateProgress(id: "non-existent", progress: 0.5)
        
        // Then - Should not crash and should not create operation
        XCTAssertEqual(progressTracker.activeOperations.count, 0)
    }
    
    // MARK: - Query Tests
    
    func testGetActiveOperationsByType() {
        // Given
        let _ = progressTracker.startOperation(title: "Create 1", type: .createProfile)
        let _ = progressTracker.startOperation(title: "Create 2", type: .createProfile)
        let _ = progressTracker.startOperation(title: "Update 1", type: .updateProfile)
        
        // When
        let createOperations = progressTracker.getActiveOperations(ofType: .createProfile)
        let updateOperations = progressTracker.getActiveOperations(ofType: .updateProfile)
        let deleteOperations = progressTracker.getActiveOperations(ofType: .deleteProfile)
        
        // Then
        XCTAssertEqual(createOperations.count, 2)
        XCTAssertEqual(updateOperations.count, 1)
        XCTAssertEqual(deleteOperations.count, 0)
    }
    
    func testGetOverallProgress() {
        // Given
        let id1 = progressTracker.startOperation(title: "Op 1", type: .createProfile)
        let id2 = progressTracker.startOperation(title: "Op 2", type: .createProfile)
        let id3 = progressTracker.startOperation(title: "Op 3", type: .updateProfile)
        
        progressTracker.updateProgress(id: id1, progress: 0.2)
        progressTracker.updateProgress(id: id2, progress: 0.8)
        progressTracker.updateProgress(id: id3, progress: 0.6)
        
        // When
        let createProgress = progressTracker.getOverallProgress(forType: .createProfile)
        let updateProgress = progressTracker.getOverallProgress(forType: .updateProfile)
        let deleteProgress = progressTracker.getOverallProgress(forType: .deleteProfile)
        
        // Then
        XCTAssertEqual(createProgress, 0.5, accuracy: 0.01) // (0.2 + 0.8) / 2
        XCTAssertEqual(updateProgress, 0.6, accuracy: 0.01)
        XCTAssertEqual(deleteProgress, 0.0) // No operations
    }
    
    // MARK: - Statistics Tests
    
    func testStatistics() {
        // Given
        let id1 = progressTracker.startOperation(title: "Op 1", type: .createProfile)
        let id2 = progressTracker.startOperation(title: "Op 2", type: .updateProfile)
        
        progressTracker.completeOperation(id: id1, success: true)
        progressTracker.completeOperation(id: id2, success: false, error: TestError.testFailure)
        
        let _ = progressTracker.startOperation(title: "Op 3", type: .uploadProfileImage)
        
        // When
        let statistics = progressTracker.getStatistics()
        
        // Then
        XCTAssertEqual(statistics.activeOperations, 1)
        XCTAssertEqual(statistics.totalCompleted, 2)
        XCTAssertEqual(statistics.successfulOperations, 1)
        XCTAssertEqual(statistics.failedOperations, 1)
        XCTAssertEqual(statistics.successRate, 0.5, accuracy: 0.01)
    }
    
    func testClearHistory() {
        // Given
        let operationId = progressTracker.startOperation(title: "Test", type: .createProfile)
        progressTracker.completeOperation(id: operationId, success: true)
        
        // When
        progressTracker.clearHistory()
        
        // Then
        XCTAssertEqual(progressTracker.completedOperations.count, 0)
    }
    
    // MARK: - Convenience Method Tests
    
    func testStartProfileOperation() {
        // When
        let operationId = progressTracker.startProfileOperation(
            title: "Create Profile",
            type: .createProfile,
            estimatedDuration: 15.0
        )
        
        // Then
        XCTAssertNotNil(progressTracker.activeOperations[operationId])
        XCTAssertEqual(progressTracker.activeOperations[operationId]?.type, .createProfile)
        XCTAssertTrue(progressTracker.activeOperations[operationId]?.isCancellable ?? false)
    }
    
    func testStartImageUploadOperation() {
        // When
        let operationId = progressTracker.startImageUploadOperation(
            title: "Upload Image",
            estimatedDuration: 30.0
        )
        
        // Then
        XCTAssertNotNil(progressTracker.activeOperations[operationId])
        XCTAssertEqual(progressTracker.activeOperations[operationId]?.type, .uploadProfileImage)
    }
    
    func testUpdateProgressWithSteps() {
        // Given
        let operationId = progressTracker.startOperation(title: "Multi-step", type: .updateProfile)
        
        // When
        progressTracker.updateProgressWithSteps(
            id: operationId,
            currentStep: 3,
            totalSteps: 5,
            stepMessage: "Processing step 3"
        )
        
        // Then
        XCTAssertEqual(progressTracker.getProgress(id: operationId), 0.6, accuracy: 0.01)
        XCTAssertEqual(progressTracker.getStatusMessage(id: operationId), "Processing step 3")
        XCTAssertEqual(progressTracker.activeOperations[operationId]?.currentStep, "3/5")
    }
    
    func testCompleteSuccessfully() {
        // Given
        let operationId = progressTracker.startOperation(title: "Test", type: .createProfile)
        
        // When
        progressTracker.completeSuccessfully(id: operationId, result: "Test Result")
        
        // Then
        XCTAssertEqual(progressTracker.activeOperations.count, 0)
        XCTAssertEqual(progressTracker.completedOperations.count, 1)
        XCTAssertTrue(progressTracker.completedOperations.first?.success ?? false)
        XCTAssertEqual(progressTracker.completedOperations.first?.finalProgress, 1.0)
    }
    
    func testCompleteWithFailure() {
        // Given
        let operationId = progressTracker.startOperation(title: "Test", type: .createProfile)
        let error = TestError.testFailure
        
        // When
        progressTracker.completeWithFailure(id: operationId, error: error)
        
        // Then
        XCTAssertEqual(progressTracker.activeOperations.count, 0)
        XCTAssertEqual(progressTracker.completedOperations.count, 1)
        XCTAssertFalse(progressTracker.completedOperations.first?.success ?? true)
        XCTAssertNotNil(progressTracker.completedOperations.first?.error)
    }
    
    // MARK: - UI Integration Tests
    
    func testGetFormattedProgress() {
        // Given
        let operationId = progressTracker.startOperation(title: "Test", type: .createProfile)
        progressTracker.updateProgress(id: operationId, progress: 0.75)
        
        // When
        let formattedProgress = progressTracker.getFormattedProgress(id: operationId)
        
        // Then
        XCTAssertEqual(formattedProgress, "75%")
    }
    
    func testGetFormattedTimeRemaining() {
        // Given
        let operationId = progressTracker.startOperation(
            title: "Test",
            type: .createProfile,
            estimatedDuration: 120.0 // 2 minutes
        )
        
        // When
        let timeRemaining = progressTracker.getFormattedTimeRemaining(id: operationId)
        
        // Then
        XCTAssertNotNil(timeRemaining)
        XCTAssertTrue(timeRemaining?.contains("分") ?? false)
    }
    
    func testGetOperationStatus() {
        // Given
        let operationId = progressTracker.startOperation(title: "Test", type: .createProfile)
        
        // When & Then
        XCTAssertEqual(progressTracker.getOperationStatus(id: operationId), .starting)
        
        progressTracker.updateProgress(id: operationId, progress: 0.5)
        XCTAssertEqual(progressTracker.getOperationStatus(id: operationId), .inProgress)
        
        progressTracker.updateProgress(id: operationId, progress: 1.0)
        XCTAssertEqual(progressTracker.getOperationStatus(id: operationId), .completing)
        
        progressTracker.cancelOperation(id: operationId)
        XCTAssertEqual(progressTracker.getOperationStatus(id: "non-existent"), .notFound)
    }
    
    // MARK: - CancellationToken Tests
    
    func testCancellationToken() {
        // Given
        let token = CancellationToken()
        
        // When & Then
        XCTAssertFalse(token.isCancelled)
        
        token.cancel(reason: "Test cancellation")
        XCTAssertTrue(token.isCancelled)
        XCTAssertEqual(token.cancellationReason, "Test cancellation")
        
        // Should throw when cancelled
        XCTAssertThrowsError(try token.throwIfCancelled())
    }
    
    // MARK: - ProgressOperation Tests
    
    func testProgressOperationProperties() {
        // Given
        let operation = ProgressOperation(
            id: "test-id",
            title: "Test Operation",
            type: .createProfile,
            estimatedDuration: 60.0,
            isCancellable: true
        )
        
        // When & Then
        XCTAssertEqual(operation.id, "test-id")
        XCTAssertEqual(operation.title, "Test Operation")
        XCTAssertEqual(operation.type, .createProfile)
        XCTAssertTrue(operation.isCancellable)
        XCTAssertNotNil(operation.estimatedCompletion)
        XCTAssertGreaterThanOrEqual(operation.elapsedTime, 0)
    }
    
    // MARK: - Helper Types
    
    enum TestError: Error {
        case testFailure
    }
}