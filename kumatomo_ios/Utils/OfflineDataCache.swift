import Foundation
import Combine

// MARK: - Offline Data Cache for Profile Information

@MainActor
class OfflineDataCache: ObservableObject {
    static let shared = OfflineDataCache()
    
    @Published var cachedProfiles: [String: CachedProfile] = [:]
    @Published var cacheStatus: CacheStatus = .idle
    @Published var lastSyncDate: Date?
    
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private let maxCacheSize = 50
    private let defaultTTL: TimeInterval = 3600 // 1 hour
    private let persistenceKey = "ProfileCache"
    
    private init() {
        loadPersistedCache()
        setupNetworkMonitoring()
        startCacheCleanupTimer()
    }
    
    // MARK: - Cache Management
    
    /// Caches a profile with TTL
    func cacheProfile(_ profile: User, ttl: TimeInterval? = nil) {
        let cachedProfile = CachedProfile(
            profile: profile,
            cachedAt: Date(),
            ttl: ttl ?? defaultTTL,
            source: networkMonitor.isConnected ? .network : .offline
        )
        
        cachedProfiles[String(profile.id)] = cachedProfile
        
        // Enforce cache size limit
        if cachedProfiles.count > maxCacheSize {
            removeOldestCacheEntry()
        }
        
        persistCache()
        print("💾 Cached profile: \(profile.id)")
    }
    
    /// Retrieves a cached profile if valid
    func getCachedProfile(id: String) -> User? {
        guard let cachedProfile = cachedProfiles[id] else {
            return nil
        }
        
        // Check if cache entry is still valid
        if cachedProfile.isExpired {
            cachedProfiles.removeValue(forKey: id)
            persistCache()
            print("🗑️ Removed expired cache entry: \(id)")
            return nil
        }
        
        // Update access time for LRU
        var updatedProfile = cachedProfile
        updatedProfile.lastAccessed = Date()
        cachedProfiles[id] = updatedProfile
        
        print("📖 Retrieved cached profile: \(id)")
        return cachedProfile.profile
    }
    
    /// Invalidates a specific profile cache
    func invalidateProfile(id: String) {
        cachedProfiles.removeValue(forKey: id)
        persistCache()
        print("❌ Invalidated cache for profile: \(id)")
    }
    
    /// Clears all cached profiles
    func clearCache() {
        cachedProfiles.removeAll()
        persistCache()
        print("🧹 Cleared all cached profiles")
    }
    
    /// Removes expired cache entries
    func cleanupExpiredEntries() {
        let expiredKeys = cachedProfiles.compactMap { key, value in
            value.isExpired ? key : nil
        }
        
        for key in expiredKeys {
            cachedProfiles.removeValue(forKey: key)
        }
        
        if !expiredKeys.isEmpty {
            persistCache()
            print("🧹 Cleaned up \(expiredKeys.count) expired cache entries")
        }
    }
    
    // MARK: - Cache Validation and Sync
    
    /// Checks if cached data is available for offline use
    func hasValidCachedProfile(id: String) -> Bool {
        guard let cachedProfile = cachedProfiles[id] else {
            return false
        }
        return !cachedProfile.isExpired
    }
    
    /// Syncs cached data with server when online
    func syncCacheWithServer() async {
        guard networkMonitor.isConnected else {
            print("📡 Cannot sync cache: offline")
            return
        }
        
        cacheStatus = .syncing
        
        let userAPIService = UserAPIService()
        var syncedCount = 0
        var failedCount = 0
        
        for (profileId, cachedProfile) in cachedProfiles {
            do {
                // Fetch fresh data from server
                let freshProfile = try await userAPIService.fetchProfileAsync(userID: profileId)
                
                // Update cache with fresh data
                cacheProfile(freshProfile)
                syncedCount += 1
                
            } catch {
                print("❌ Failed to sync profile \(profileId): \(error)")
                failedCount += 1
            }
        }
        
        lastSyncDate = Date()
        cacheStatus = .idle
        
        print("🔄 Cache sync complete. Synced: \(syncedCount), Failed: \(failedCount)")
    }
    
    /// Validates cache integrity
    func validateCacheIntegrity() -> CacheValidationResult {
        var corruptedEntries: [String] = []
        var expiredEntries: [String] = []
        var validEntries: [String] = []
        
        for (profileId, cachedProfile) in cachedProfiles {
            // Check for data corruption
            if cachedProfile.profile.id <= 0 || (cachedProfile.profile.name?.isEmpty ?? true) {
                corruptedEntries.append(profileId)
                continue
            }
            
            // Check expiration
            if cachedProfile.isExpired {
                expiredEntries.append(profileId)
                continue
            }
            
            validEntries.append(profileId)
        }
        
        // Remove corrupted entries
        for profileId in corruptedEntries {
            cachedProfiles.removeValue(forKey: profileId)
        }
        
        if !corruptedEntries.isEmpty {
            persistCache()
        }
        
        return CacheValidationResult(
            totalEntries: cachedProfiles.count + corruptedEntries.count,
            validEntries: validEntries.count,
            expiredEntries: expiredEntries.count,
            corruptedEntries: corruptedEntries.count
        )
    }
    
    // MARK: - Private Methods
    
    private func removeOldestCacheEntry() {
        guard let oldestEntry = cachedProfiles.min(by: { $0.value.lastAccessed < $1.value.lastAccessed }) else {
            return
        }
        
        cachedProfiles.removeValue(forKey: oldestEntry.key)
        print("🗑️ Removed oldest cache entry: \(oldestEntry.key)")
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                if isConnected {
                    Task { @MainActor in
                        await self?.syncCacheWithServer()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func startCacheCleanupTimer() {
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupExpiredEntries()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Persistence
    
    private func persistCache() {
        do {
            let data = try JSONEncoder().encode(cachedProfiles)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            print("❌ Failed to persist cache: \(error)")
        }
    }
    
    private func loadPersistedCache() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else {
            return
        }
        
        do {
            cachedProfiles = try JSONDecoder().decode([String: CachedProfile].self, from: data)
            print("📂 Loaded \(cachedProfiles.count) cached profiles")
            
            // Validate loaded cache
            let validationResult = validateCacheIntegrity()
            if validationResult.corruptedEntries > 0 {
                print("⚠️ Found \(validationResult.corruptedEntries) corrupted cache entries, removed")
            }
            
        } catch {
            print("❌ Failed to load persisted cache: \(error)")
            // Clear corrupted data
            UserDefaults.standard.removeObject(forKey: persistenceKey)
        }
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStatistics() -> CacheStatistics {
        let now = Date()
        let expiredCount = cachedProfiles.values.filter { $0.isExpired }.count
        let validCount = cachedProfiles.count - expiredCount
        
        let totalSize = cachedProfiles.values.reduce(0) { result, cachedProfile in
            return result + cachedProfile.estimatedSize
        }
        
        let averageAge = cachedProfiles.values.isEmpty ? 0 : 
            cachedProfiles.values.map { now.timeIntervalSince($0.cachedAt) }.reduce(0, +) / Double(cachedProfiles.count)
        
        let sourceBreakdown = Dictionary(grouping: cachedProfiles.values) { $0.source }
            .mapValues { $0.count }
        
        return CacheStatistics(
            totalEntries: cachedProfiles.count,
            validEntries: validCount,
            expiredEntries: expiredCount,
            totalSizeBytes: totalSize,
            averageAgeSeconds: averageAge,
            sourceBreakdown: sourceBreakdown,
            lastSyncDate: lastSyncDate,
            hitRate: 0.0 // Would need to track cache hits/misses for this
        )
    }
}

// MARK: - Supporting Types

struct CachedProfile: Codable {
    let profile: User
    let cachedAt: Date
    let ttl: TimeInterval
    let source: CacheSource
    var lastAccessed: Date
    
    init(profile: User, cachedAt: Date, ttl: TimeInterval, source: CacheSource) {
        self.profile = profile
        self.cachedAt = cachedAt
        self.ttl = ttl
        self.source = source
        self.lastAccessed = cachedAt
    }
    
    var isExpired: Bool {
        return Date().timeIntervalSince(cachedAt) > ttl
    }
    
    var remainingTTL: TimeInterval {
        return max(0, ttl - Date().timeIntervalSince(cachedAt))
    }
    
    var estimatedSize: Int {
        // Rough estimate of memory usage
        let baseSize = 200 // Base object overhead
        let stringSize = ((profile.name?.count ?? 0) + (profile.email?.count ?? 0) + (profile.bio?.count ?? 0)) * 2 // UTF-16
        let urlSize = ((profile.profileImageURL?.count ?? 0) + (profile.coverImageURL?.count ?? 0)) * 2
        return baseSize + stringSize + urlSize
    }
}

enum CacheSource: String, Codable {
    case network = "network"
    case offline = "offline"
    case manual = "manual"
}

enum CacheStatus: String, CaseIterable {
    case idle = "idle"
    case syncing = "syncing"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .idle:
            return "待機中"
        case .syncing:
            return "同期中"
        case .error:
            return "エラー"
        }
    }
}

struct CacheValidationResult {
    let totalEntries: Int
    let validEntries: Int
    let expiredEntries: Int
    let corruptedEntries: Int
    
    var isHealthy: Bool {
        return corruptedEntries == 0 && expiredEntries < totalEntries / 2
    }
}

struct CacheStatistics {
    let totalEntries: Int
    let validEntries: Int
    let expiredEntries: Int
    let totalSizeBytes: Int
    let averageAgeSeconds: TimeInterval
    let sourceBreakdown: [CacheSource: Int]
    let lastSyncDate: Date?
    let hitRate: Double
    
    var totalSizeMB: Double {
        return Double(totalSizeBytes) / (1024 * 1024)
    }
    
    var averageAgeMinutes: Double {
        return averageAgeSeconds / 60
    }
}

// MARK: - Extensions

extension OfflineDataCache {
    /// Preloads profiles for offline use
    func preloadProfiles(_ profiles: [User]) {
        for profile in profiles {
            cacheProfile(profile, ttl: defaultTTL * 2) // Longer TTL for preloaded data
        }
        print("📦 Preloaded \(profiles.count) profiles for offline use")
    }
    
    /// Gets all cached profile IDs
    func getCachedProfileIDs() -> [String] {
        return Array(cachedProfiles.keys)
    }
    
    /// Checks if cache needs refresh based on age and network status
    func shouldRefreshCache() -> Bool {
        guard networkMonitor.isConnected else {
            return false
        }
        
        // Refresh if no sync in last hour
        if let lastSync = lastSyncDate {
            return Date().timeIntervalSince(lastSync) > 3600
        }
        
        return true
    }
    
    /// Gets cache health score (0-100)
    func getCacheHealthScore() -> Int {
        let stats = getCacheStatistics()
        
        if stats.totalEntries == 0 {
            return 100 // Empty cache is considered healthy
        }
        
        let validRatio = Double(stats.validEntries) / Double(stats.totalEntries)
        let ageScore = min(100, max(0, 100 - Int(stats.averageAgeMinutes / 60 * 10))) // Deduct 10 points per hour
        
        return Int(validRatio * Double(ageScore))
    }
}
