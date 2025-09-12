import XCTest
import Combine
@testable import kumatomo

@MainActor
class OfflineDataCacheTests: XCTestCase {
    
    var offlineDataCache: OfflineDataCache!
    var mockNetworkMonitor: MockNetworkMonitor!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        offlineDataCache = OfflineDataCache.shared
        mockNetworkMonitor = MockNetworkMonitor()
        cancellables = Set<AnyCancellable>()
        
        // Clear any existing cache
        offlineDataCache.clearCache()
    }
    
    override func tearDown() {
        offlineDataCache.clearCache()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Cache Management Tests
    
    func testCacheProfile() {
        // Given
        let testUser = createTestUser()
        
        // When
        offlineDataCache.cacheProfile(testUser)
        
        // Then
        XCTAssertEqual(offlineDataCache.cachedProfiles.count, 1)
        XCTAssertNotNil(offlineDataCache.cachedProfiles[testUser.id])
    }
    
    func testGetCachedProfile() {
        // Given
        let testUser = createTestUser()
        offlineDataCache.cacheProfile(testUser)
        
        // When
        let cachedUser = offlineDataCache.getCachedProfile(id: testUser.id)
        
        // Then
        XCTAssertNotNil(cachedUser)
        XCTAssertEqual(cachedUser?.id, testUser.id)
        XCTAssertEqual(cachedUser?.name, testUser.name)
    }
    
    func testGetNonExistentProfile() {
        // Given
        let nonExistentId = "non-existent-id"
        
        // When
        let cachedUser = offlineDataCache.getCachedProfile(id: nonExistentId)
        
        // Then
        XCTAssertNil(cachedUser)
    }
    
    func testInvalidateProfile() {
        // Given
        let testUser = createTestUser()
        offlineDataCache.cacheProfile(testUser)
        
        // When
        offlineDataCache.invalidateProfile(id: testUser.id)
        
        // Then
        XCTAssertNil(offlineDataCache.getCachedProfile(id: testUser.id))
        XCTAssertEqual(offlineDataCache.cachedProfiles.count, 0)
    }
    
    func testClearCache() {
        // Given
        let testUser1 = createTestUser()
        let testUser2 = createTestUser()
        offlineDataCache.cacheProfile(testUser1)
        offlineDataCache.cacheProfile(testUser2)
        
        // When
        offlineDataCache.clearCache()
        
        // Then
        XCTAssertEqual(offlineDataCache.cachedProfiles.count, 0)
    }
    
    // MARK: - TTL and Expiration Tests
    
    func testCacheExpiration() {
        // Given
        let testUser = createTestUser()
        let shortTTL: TimeInterval = 0.1 // 100ms
        
        // When
        offlineDataCache.cacheProfile(testUser, ttl: shortTTL)
        
        // Wait for expiration
        let expectation = XCTestExpectation(description: "Cache expiration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        let cachedUser = offlineDataCache.getCachedProfile(id: testUser.id)
        XCTAssertNil(cachedUser)
    }
    
    func testHasValidCachedProfile() {
        // Given
        let testUser = createTestUser()
        offlineDataCache.cacheProfile(testUser)
        
        // When & Then
        XCTAssertTrue(offlineDataCache.hasValidCachedProfile(id: testUser.id))
        XCTAssertFalse(offlineDataCache.hasValidCachedProfile(id: "non-existent"))
    }
    
    func testCleanupExpiredEntries() {
        // Given
        let testUser1 = createTestUser()
        let testUser2 = createTestUser()
        
        offlineDataCache.cacheProfile(testUser1, ttl: 3600) // Valid
        offlineDataCache.cacheProfile(testUser2, ttl: 0.1) // Will expire
        
        // Wait for one to expire
        let expectation = XCTestExpectation(description: "Cache expiration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // When
        offlineDataCache.cleanupExpiredEntries()
        
        // Then
        XCTAssertEqual(offlineDataCache.cachedProfiles.count, 1)
        XCTAssertNotNil(offlineDataCache.getCachedProfile(id: testUser1.id))
        XCTAssertNil(offlineDataCache.getCachedProfile(id: testUser2.id))
    }
    
    // MARK: - Cache Size Management Tests
    
    func testMaxCacheSize() {
        // Given
        let maxSize = 50
        
        // When - Add more than max size
        for i in 0...(maxSize + 5) {
            let user = createTestUser()
            user.id = "user-\(i)"
            offlineDataCache.cacheProfile(user)
        }
        
        // Then
        XCTAssertLesssThanOrEqual(offlineDataCache.cachedProfiles.count, maxSize)
    }
    
    // MARK: - Cache Validation Tests
    
    func testValidateCacheIntegrity() {
        // Given
        let validUser = createTestUser()
        let corruptedUser = createTestUser()
        corruptedUser.id = "" // Corrupted data
        corruptedUser.name = ""
        
        offlineDataCache.cacheProfile(validUser)
        offlineDataCache.cacheProfile(corruptedUser)
        
        // When
        let validationResult = offlineDataCache.validateCacheIntegrity()
        
        // Then
        XCTAssertEqual(validationResult.validEntries, 1)
        XCTAssertEqual(validationResult.corruptedEntries, 1)
        XCTAssertFalse(validationResult.isHealthy)
    }
    
    // MARK: - Cache Statistics Tests
    
    func testCacheStatistics() {
        // Given
        let testUser1 = createTestUser()
        let testUser2 = createTestUser()
        
        offlineDataCache.cacheProfile(testUser1)
        offlineDataCache.cacheProfile(testUser2)
        
        // When
        let statistics = offlineDataCache.getCacheStatistics()
        
        // Then
        XCTAssertEqual(statistics.totalEntries, 2)
        XCTAssertEqual(statistics.validEntries, 2)
        XCTAssertEqual(statistics.expiredEntries, 0)
        XCTAssertGreaterThan(statistics.totalSizeBytes, 0)
    }
    
    func testCacheHealthScore() {
        // Given
        let testUser = createTestUser()
        offlineDataCache.cacheProfile(testUser)
        
        // When
        let healthScore = offlineDataCache.getCacheHealthScore()
        
        // Then
        XCTAssertGreaterThanOrEqual(healthScore, 0)
        XCTAssertLessThanOrEqual(healthScore, 100)
    }
    
    func testEmptyCacheHealthScore() {
        // Given - Empty cache
        
        // When
        let healthScore = offlineDataCache.getCacheHealthScore()
        
        // Then
        XCTAssertEqual(healthScore, 100) // Empty cache is considered healthy
    }
    
    // MARK: - Preload and Utility Tests
    
    func testPreloadProfiles() {
        // Given
        let users = [createTestUser(), createTestUser(), createTestUser()]
        
        // When
        offlineDataCache.preloadProfiles(users)
        
        // Then
        XCTAssertEqual(offlineDataCache.cachedProfiles.count, 3)
        
        for user in users {
            XCTAssertNotNil(offlineDataCache.getCachedProfile(id: user.id))
        }
    }
    
    func testGetCachedProfileIDs() {
        // Given
        let testUser1 = createTestUser()
        let testUser2 = createTestUser()
        
        offlineDataCache.cacheProfile(testUser1)
        offlineDataCache.cacheProfile(testUser2)
        
        // When
        let cachedIDs = offlineDataCache.getCachedProfileIDs()
        
        // Then
        XCTAssertEqual(cachedIDs.count, 2)
        XCTAssertTrue(cachedIDs.contains(testUser1.id))
        XCTAssertTrue(cachedIDs.contains(testUser2.id))
    }
    
    func testShouldRefreshCache() {
        // Given - Mock network as connected
        mockNetworkMonitor.simulateOnline()
        
        // When & Then
        XCTAssertTrue(offlineDataCache.shouldRefreshCache()) // No previous sync
        
        // Set recent sync date
        offlineDataCache.lastSyncDate = Date()
        XCTAssertFalse(offlineDataCache.shouldRefreshCache()) // Recent sync
        
        // Set old sync date
        offlineDataCache.lastSyncDate = Date().addingTimeInterval(-7200) // 2 hours ago
        XCTAssertTrue(offlineDataCache.shouldRefreshCache()) // Old sync
    }
    
    // MARK: - Persistence Tests
    
    func testPersistence() {
        // Given
        let testUser = createTestUser()
        offlineDataCache.cacheProfile(testUser)
        
        // When - Create new instance to test persistence
        let newCache = OfflineDataCache.shared
        
        // Then
        XCTAssertEqual(newCache.cachedProfiles.count, 1)
        XCTAssertNotNil(newCache.getCachedProfile(id: testUser.id))
    }
    
    // MARK: - CachedProfile Tests
    
    func testCachedProfileExpiration() {
        // Given
        let testUser = createTestUser()
        let cachedProfile = CachedProfile(
            profile: testUser,
            cachedAt: Date().addingTimeInterval(-3700), // 1 hour and 2 minutes ago
            ttl: 3600, // 1 hour TTL
            source: .network
        )
        
        // When & Then
        XCTAssertTrue(cachedProfile.isExpired)
        XCTAssertEqual(cachedProfile.remainingTTL, 0)
    }
    
    func testCachedProfileNotExpired() {
        // Given
        let testUser = createTestUser()
        let cachedProfile = CachedProfile(
            profile: testUser,
            cachedAt: Date().addingTimeInterval(-1800), // 30 minutes ago
            ttl: 3600, // 1 hour TTL
            source: .network
        )
        
        // When & Then
        XCTAssertFalse(cachedProfile.isExpired)
        XCTAssertGreaterThan(cachedProfile.remainingTTL, 0)
    }
    
    func testCachedProfileEstimatedSize() {
        // Given
        let testUser = createTestUser()
        let cachedProfile = CachedProfile(
            profile: testUser,
            cachedAt: Date(),
            ttl: 3600,
            source: .network
        )
        
        // When
        let estimatedSize = cachedProfile.estimatedSize
        
        // Then
        XCTAssertGreaterThan(estimatedSize, 0)
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
}