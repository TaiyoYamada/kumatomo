import Foundation
import Combine

// MARK: - ProfileCache

class ProfileCache: ObservableObject {
    static let shared = ProfileCache()

    private var cache: [String: CachedUser] = [:]
    private let cacheQueue = DispatchQueue(label: "profile.cache", attributes: .concurrent)
    private let defaultTTL: TimeInterval = 300

    private init() {
        startCacheCleanup()
    }

    func getUser(id: String) -> User? {
        return cacheQueue.sync {
            guard let cachedUser = cache[id] else { return nil }

            if cachedUser.isExpired {
                cache.removeValue(forKey: id)
                return nil
            }

            print("📱 キャッシュヒット: \(id)")
            return cachedUser.user
        }
    }

    func setUser(_ user: User, ttl: TimeInterval? = nil) {
        let expirationTime = Date().addingTimeInterval(ttl ?? defaultTTL)
        let cachedUser = CachedUser(user: user, expirationTime: expirationTime)

        cacheQueue.async(flags: .barrier) {
            self.cache["\(user.id)"] = cachedUser
            print("📱 キャッシュ保存: \(user.id)")
        }
    }

    func removeUser(id: String) {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeValue(forKey: id)
            print("📱 キャッシュ削除: \(id)")
        }
    }

    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAll()
            print("📱 キャッシュクリア")
        }
    }

    @MainActor
    func reloadFromServer() async throws {
        clearCache()
    }

    func getCacheSize() -> Int {
        return cacheQueue.sync {
            return cache.count
        }
    }

    private func startCacheCleanup() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.cleanupExpiredEntries()
        }
    }

    private func cleanupExpiredEntries() {
        cacheQueue.async(flags: .barrier) {
            let expiredKeys = self.cache.compactMap { key, cachedUser in
                cachedUser.isExpired ? key : nil
            }

            for key in expiredKeys {
                self.cache.removeValue(forKey: key)
            }

            if !expiredKeys.isEmpty {
                print("📱 期限切れキャッシュ削除: \(expiredKeys.count)件")
            }
        }
    }
}

// MARK: - CachedUser

private struct CachedUser {
    let user: User
    let expirationTime: Date

    var isExpired: Bool {
        return Date() > expirationTime
    }
}

extension ProfileCache {
    struct CacheStats {
        let totalEntries: Int
        let expiredEntries: Int
        let validEntries: Int
        let cacheHitRate: Double
    }

    func getCacheStats() -> CacheStats {
        return cacheQueue.sync {
            let total = cache.count
            let expired = cache.values.filter(\.isExpired).count
            let valid = total - expired

            return CacheStats(
                totalEntries: total,
                expiredEntries: expired,
                validEntries: valid,
                cacheHitRate: 0.0
            )
        }
    }
}
