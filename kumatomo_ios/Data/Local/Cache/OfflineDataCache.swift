import Foundation
import Combine

// MARK: - OfflineDataCache

@MainActor
class OfflineDataCache: ObservableObject {
    static let shared = OfflineDataCache()

    @Published var cachedProfiles: [String: CachedProfile] = [:]
    @Published var cacheStatus: CacheStatus = .idle
    @Published var lastSyncDate: Date?

    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private let maxCacheSize = 50
    private let defaultTTL: TimeInterval = 3_600
    private let persistenceKey = "ProfileCache"

    private init() {
        loadPersistedCache()
        setupNetworkMonitoring()
        startCacheCleanupTimer()
    }

    func cacheProfile(_ profile: User, ttl: TimeInterval? = nil) {
        let cachedProfile = CachedProfile(
            profile: profile,
            cachedAt: Date(),
            ttl: ttl ?? defaultTTL,
            source: networkMonitor.isConnected ? .network : .offline
        )

        cachedProfiles[String(profile.id)] = cachedProfile

        if cachedProfiles.count > maxCacheSize {
            removeOldestCacheEntry()
        }

        persistCache()
        print("💾 Cached profile: \(profile.id)")
    }

    func getCachedProfile(id: String) -> User? {
        guard let cachedProfile = cachedProfiles[id] else {
            return nil
        }

        if cachedProfile.isExpired {
            cachedProfiles.removeValue(forKey: id)
            persistCache()
            print("🗑️ Removed expired cache entry: \(id)")
            return nil
        }

        var updatedProfile = cachedProfile
        updatedProfile.lastAccessed = Date()
        cachedProfiles[id] = updatedProfile

        print("📖 Retrieved cached profile: \(id)")
        return cachedProfile.profile
    }

    func invalidateProfile(id: String) {
        cachedProfiles.removeValue(forKey: id)
        persistCache()
        print("❌ Invalidated cache for profile: \(id)")
    }

    func clearCache() {
        cachedProfiles.removeAll()
        persistCache()
        print("🧹 Cleared all cached profiles")
    }

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

    func hasValidCachedProfile(id: String) -> Bool {
        guard let cachedProfile = cachedProfiles[id] else {
            return false
        }
        return !cachedProfile.isExpired
    }

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
                let freshProfile = try await userAPIService.fetchProfileAsync(userID: profileId)

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

    func validateCacheIntegrity() -> CacheValidationResult {
        var corruptedEntries: [String] = []
        var expiredEntries: [String] = []
        var validEntries: [String] = []

        for (profileId, cachedProfile) in cachedProfiles {
            if cachedProfile.profile.id <= 0 || (cachedProfile.profile.name?.isEmpty ?? true) {
                corruptedEntries.append(profileId)
                continue
            }

            if cachedProfile.isExpired {
                expiredEntries.append(profileId)
                continue
            }

            validEntries.append(profileId)
        }

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

    private func removeOldestCacheEntry() {
        guard let oldestEntry = cachedProfiles.min(by: { $0.value.lastAccessed < $1.value.lastAccessed }) else {
            return
        }

        cachedProfiles.removeValue(forKey: oldestEntry.key)
        print("🗑️ Removed oldest cache entry: \(oldestEntry.key)")
    }

    private func setupNetworkMonitoring() {
        NotificationCenter.default.publisher(for: .NetworkConnectivityChanged)
            .compactMap { $0.userInfo?["isConnected"] as? Bool }
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
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupExpiredEntries()
            }
            .store(in: &cancellables)
    }

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

            let validationResult = validateCacheIntegrity()
            if validationResult.corruptedEntries > 0 {
                print("⚠️ Found \(validationResult.corruptedEntries) corrupted cache entries, removed")
            }

        } catch {
            print("❌ Failed to load persisted cache: \(error)")
            UserDefaults.standard.removeObject(forKey: persistenceKey)
        }
    }

    func getCacheStatistics() -> CacheStatistics {
        let now = Date()
        let expiredCount = cachedProfiles.values.filter(\.isExpired).count
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
            hitRate: 0.0
        )
    }
}

// MARK: - CachedProfile

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
        lastAccessed = cachedAt
    }

    var isExpired: Bool {
        return Date().timeIntervalSince(cachedAt) > ttl
    }

    var remainingTTL: TimeInterval {
        return max(0, ttl - Date().timeIntervalSince(cachedAt))
    }

    var estimatedSize: Int {
        let baseSize = 200
        let stringSize = ((profile.name?.count ?? 0) + (profile.email?.count ?? 0) + (profile.bio?.count ?? 0)) * 2
        let urlSize = ((profile.profileImageURL?.count ?? 0) + (profile.coverImageURL?.count ?? 0)) * 2
        return baseSize + stringSize + urlSize
    }
}

// MARK: - CacheSource

enum CacheSource: String, Codable {
    case network
    case offline
    case manual
}

// MARK: - CacheStatus

enum CacheStatus: String, CaseIterable {
    case idle
    case syncing
    case error

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

// MARK: - CacheValidationResult

struct CacheValidationResult {
    let totalEntries: Int
    let validEntries: Int
    let expiredEntries: Int
    let corruptedEntries: Int

    var isHealthy: Bool {
        return corruptedEntries == 0 && expiredEntries < totalEntries / 2
    }
}

// MARK: - CacheStatistics

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
        return Double(totalSizeBytes) / (1_024 * 1_024)
    }

    var averageAgeMinutes: Double {
        return averageAgeSeconds / 60
    }
}

extension OfflineDataCache {
    func preloadProfiles(_ profiles: [User]) {
        for profile in profiles {
            cacheProfile(profile, ttl: defaultTTL * 2)
        }
        print("📦 Preloaded \(profiles.count) profiles for offline use")
    }

    func getCachedProfileIDs() -> [String] {
        return Array(cachedProfiles.keys)
    }

    func shouldRefreshCache() -> Bool {
        guard networkMonitor.isConnected else {
            return false
        }

        if let lastSync = lastSyncDate {
            return Date().timeIntervalSince(lastSync) > 3_600
        }

        return true
    }

    func getCacheHealthScore() -> Int {
        let stats = getCacheStatistics()

        if stats.totalEntries == 0 {
            return 100
        }

        let validRatio = Double(stats.validEntries) / Double(stats.totalEntries)
        let ageScore = min(100, max(0, 100 - Int(stats.averageAgeMinutes / 60 * 10)))

        return Int(validRatio * Double(ageScore))
    }
}
