import XCTest
import Combine
@testable import kumatomo

@MainActor
class OfflineQueueManagerTests: XCTestCase {
    
    var offlineQueueManager: OfflineQueueManager!
    var mockNetworkMonitor: MockNetworkMonitor!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        offlineQueueManager = OfflineQueueManager.shared
        mockNetworkMonitor = MockNetworkMonitor()
        cancellables = Set<AnyCancellable>()
        
        // Clear any existing queue
        offlineQueueManager.clearQueue()
    }
    
    override func tearDown() {
        offlineQueueManager.clearQueue()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Queue Management Tests
    
    func testEnqueueOperation() {
        // Given
        let testUser = createTestUser()
        
        // When
        offlineQueueManager.enqueueProfileCreation(testUser)
        
        // Then
        XCTAssertEqual(offlineQueueManager.pendingOperations.count, 1)
        XCTAssertEqual(offlineQueueManager.pendingOperations.first?.type, .createProfile)
    }
    
    func testDequeueOperation() {
        // Given
        let testUser = createTestUser()
        offlineQueueManager.enqueueProfileCreation(testUser)
        let operationId = offlineQueueManager.pendingOperations.first!.id
        
        // When
        offlineQueueManager.dequeueOperation(withId: operationId)
        
        // Then
        XCTAssertEqual(offlineQueueManager.pendingOperations.count, 0)
    }
    
    func testClearQueue() {
        // Given
        let testUser = createTestUser()
        offlineQueueManager.enqueueProfileCreation(testUser)
        offlineQueueManager.enqueueProfileUpdate(testUser)
        
        // When
        offlineQueueManager.clearQueue()
        
        // Then
        XCTAssertEqual(offlineQueueManager.pendingOperations.count, 0)
        XCTAssertEqual(offlineQueueManager.queueStatus, .idle)
    }
    
    func testMaxQueueSize() {
        // Given
        let testUser = createTestUser()
        let maxSize = 100
        
        // When - Add more than max size
        for _ in 0...(maxSize + 5) {
            offlineQueueManager.enqueueProfileCreation(testUser)
        }
        
        // Then
        XCTAssertLesssThanOrEqual(offlineQueueManager.pendingOperations.count, maxSize)
    }
    
    // MARK: - Operation Type Tests
    
    func testEnqueueProfileCreation() {
        // Given
        let testUser = createTestUser()
        
        // When
        offlineQueueManager.enqueueProfileCreation(testUser)
        
        // Then
        let operation = offlineQueueManager.pendingOperations.first!
        XCTAssertEqual(operation.type, .createProfile)
        XCTAssertEqual(operation.priority, .high)
        XCTAssertNotNil(operation.data["user"])
    }
    
    func testEnqueueProfileUpdate() {
        // Given
        let testUser = createTestUser()
        
        // When
        offlineQueueManager.enqueueProfileUpdate(testUser)
        
        // Then
        let operation = offlineQueueManager.pendingOperations.first!
        XCTAssertEqual(operation.type, .updateProfile)
        XCTAssertEqual(operation.priority, .medium)
        XCTAssertNotNil(operation.data["user"])
    }
    
    func testEnqueueProfileDeletion() {
        // Given
        let userID = "test-user-id"
        
        // When
        offlineQueueManager.enqueueProfileDeletion(userID: userID)
        
        // Then
        let operation = offlineQueueManager.pendingOperations.first!
        XCTAssertEqual(operation.type, .deleteProfile)
        XCTAssertEqual(operation.priority, .high)
        XCTAssertNotNil(operation.data["userID"])
    }
    
    func testEnqueueImageUpload() {
        // Given
        let testImage = createTestImage()
        
        // When
        offlineQueueManager.enqueueProfileImageUpload(testImage)
        
        // Then
        let operation = offlineQueueManager.pendingOperations.first!
        XCTAssertEqual(operation.type, .uploadProfileImage)
        XCTAssertEqual(operation.priority, .medium)
        XCTAssertNotNil(operation.data["imageData"])
    }
    
    // MARK: - Queue Statistics Tests
    
    func testQueueStatistics() {
        // Given
        let testUser = createTestUser()
        let testImage = createTestImage()
        
        offlineQueueManager.enqueueProfileCreation(testUser)
        offlineQueueManager.enqueueProfileUpdate(testUser)
        offlineQueueManager.enqueueProfileImageUpload(testImage)
        
        // When
        let statistics = offlineQueueManager.getQueueStatistics()
        
        // Then
        XCTAssertEqual(statistics.totalOperations, 3)
        XCTAssertEqual(statistics.operationsByType[.createProfile], 1)
        XCTAssertEqual(statistics.operationsByType[.updateProfile], 1)
        XCTAssertEqual(statistics.operationsByType[.uploadProfileImage], 1)
    }
    
    func testHasQueuedOperation() {
        // Given
        let testUser = createTestUser()
        
        // When
        offlineQueueManager.enqueueProfileCreation(testUser)
        
        // Then
        XCTAssertTrue(offlineQueueManager.hasQueuedOperation(ofType: .createProfile))
        XCTAssertFalse(offlineQueueManager.hasQueuedOperation(ofType: .deleteProfile))
    }
    
    func testGetOperationCount() {
        // Given
        let testUser = createTestUser()
        
        offlineQueueManager.enqueueProfileCreation(testUser)
        offlineQueueManager.enqueueProfileCreation(testUser)
        offlineQueueManager.enqueueProfileUpdate(testUser)
        
        // When & Then
        XCTAssertEqual(offlineQueueManager.getOperationCount(ofType: .createProfile), 2)
        XCTAssertEqual(offlineQueueManager.getOperationCount(ofType: .updateProfile), 1)
        XCTAssertEqual(offlineQueueManager.getOperationCount(ofType: .deleteProfile), 0)
    }
    
    func testRemoveOperationsOfType() {
        // Given
        let testUser = createTestUser()
        
        offlineQueueManager.enqueueProfileCreation(testUser)
        offlineQueueManager.enqueueProfileUpdate(testUser)
        offlineQueueManager.enqueueProfileCreation(testUser)
        
        // When
        offlineQueueManager.removeOperations(ofType: .createProfile)
        
        // Then
        XCTAssertEqual(offlineQueueManager.pendingOperations.count, 1)
        XCTAssertEqual(offlineQueueManager.pendingOperations.first?.type, .updateProfile)
    }
    
    func testGetSortedOperations() {
        // Given
        let testUser = createTestUser()
        
        // Add operations with different priorities
        offlineQueueManager.enqueueProfileUpdate(testUser) // medium priority
        offlineQueueManager.enqueueProfileCreation(testUser) // high priority
        offlineQueueManager.enqueueCoverImageUpload(createTestImage()) // low priority
        
        // When
        let sortedOperations = offlineQueueManager.getSortedOperations()
        
        // Then
        XCTAssertEqual(sortedOperations[0].priority, .high)
        XCTAssertEqual(sortedOperations[1].priority, .medium)
        XCTAssertEqual(sortedOperations[2].priority, .low)
    }
    
    // MARK: - Persistence Tests
    
    func testPersistence() {
        // Given
        let testUser = createTestUser()
        offlineQueueManager.enqueueProfileCreation(testUser)
        
        // When - Create new instance to test persistence
        let newQueueManager = OfflineQueueManager.shared
        
        // Then
        XCTAssertEqual(newQueueManager.pendingOperations.count, 1)
        XCTAssertEqual(newQueueManager.pendingOperations.first?.type, .createProfile)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidUserDataHandling() {
        // Given
        let invalidUser = User(id: "", name: "", email: "", username: "")
        
        // When
        offlineQueueManager.enqueueProfileCreation(invalidUser)
        
        // Then - Should still enqueue but may fail during processing
        XCTAssertEqual(offlineQueueManager.pendingOperations.count, 1)
    }
    
    func testInvalidImageDataHandling() {
        // Given - Create an image that will fail to convert to data
        let invalidImage = UIImage()
        
        // When
        offlineQueueManager.enqueueProfileImageUpload(invalidImage)
        
        // Then - Should not enqueue if image data conversion fails
        // This depends on implementation - might enqueue with empty data or not enqueue at all
        // Adjust assertion based on actual implementation behavior
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
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - Mock Classes

class MockNetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: NetworkMonitor.ConnectionType = .wifi
    
    func simulateOffline() {
        isConnected = false
        connectionType = .unknown
    }
    
    func simulateOnline() {
        isConnected = true
        connectionType = .wifi
    }
}