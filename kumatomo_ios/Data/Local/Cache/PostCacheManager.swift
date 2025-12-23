import Foundation

// MARK: - PostCacheManager

class PostCacheManager: ObservableObject {
    static let shared = PostCacheManager()

    private let userDefaults = UserDefaults.standard
    private let cacheExpirationInterval: TimeInterval = 300
    private let logger = AppLogger.cache

    private enum CacheKeys {
        static let allPosts = "cached_all_posts"
        static let allPostsTimestamp = "cached_all_posts_timestamp"
        static let municipalityPosts = "cached_municipality_posts_"
        static let municipalityPostsTimestamp = "cached_municipality_posts_timestamp_"
        static let followingPosts = "cached_following_posts"
        static let followingPostsTimestamp = "cached_following_posts_timestamp"
        static let reactions = "cached_reactions"
        static let bookmarks = "cached_bookmarks"
    }

    private init() {}

    func cacheAllPosts(_ posts: [Post]) {
        do {
            let data = try JSONEncoder().encode(posts)
            userDefaults.set(data, forKey: CacheKeys.allPosts)
            userDefaults.set(Date().timeIntervalSince1970, forKey: CacheKeys.allPostsTimestamp)
            logger.debug("全投稿をキャッシュ: \(posts.count)件")
        } catch {
            logger.logError(error, context: "CacheAllPosts")
        }
    }

    func getCachedAllPosts() -> [Post]? {
        guard isCacheValid(timestampKey: CacheKeys.allPostsTimestamp) else {
            logger.debug("全投稿キャッシュ期限切れ")
            return nil
        }

        guard let data = userDefaults.data(forKey: CacheKeys.allPosts) else {
            logger.debug("全投稿キャッシュなし")
            return nil
        }

        do {
            let posts = try JSONDecoder().decode([Post].self, from: data)
            logger.debug("全投稿をキャッシュから取得: \(posts.count)件")
            return posts
        } catch {
            logger.logError(error, context: "DecodeCacheAllPosts")
            return nil
        }
    }

    func cacheMunicipalityPosts(_ posts: [Post], municipality: String) {
        do {
            let data = try JSONEncoder().encode(posts)
            let key = CacheKeys.municipalityPosts + municipality
            let timestampKey = CacheKeys.municipalityPostsTimestamp + municipality

            userDefaults.set(data, forKey: key)
            userDefaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
            logger.debug("市町村投稿をキャッシュ (\(municipality)): \(posts.count)件")
        } catch {
            logger.logError(error, context: "CacheMunicipalityPosts[\(municipality)]")
        }
    }

    func getCachedMunicipalityPosts(municipality: String) -> [Post]? {
        let timestampKey = CacheKeys.municipalityPostsTimestamp + municipality
        guard isCacheValid(timestampKey: timestampKey) else {
            logger.debug("市町村投稿キャッシュ期限切れ (\(municipality))")
            return nil
        }

        let key = CacheKeys.municipalityPosts + municipality
        guard let data = userDefaults.data(forKey: key) else {
            logger.debug("市町村投稿キャッシュなし (\(municipality))")
            return nil
        }

        do {
            let posts = try JSONDecoder().decode([Post].self, from: data)
            logger.debug("市町村投稿をキャッシュから取得 (\(municipality)): \(posts.count)件")
            return posts
        } catch {
            logger.logError(error, context: "DecodeCacheMunicipalityPosts[\(municipality)]")
            return nil
        }
    }

    func cacheFollowingPosts(_ posts: [Post]) {
        do {
            let data = try JSONEncoder().encode(posts)
            userDefaults.set(data, forKey: CacheKeys.followingPosts)
            userDefaults.set(Date().timeIntervalSince1970, forKey: CacheKeys.followingPostsTimestamp)
            logger.debug("フォロー中投稿をキャッシュ: \(posts.count)件")
        } catch {
            logger.logError(error, context: "CacheFollowingPosts")
        }
    }

    func getCachedFollowingPosts() -> [Post]? {
        guard isCacheValid(timestampKey: CacheKeys.followingPostsTimestamp) else {
            logger.debug("フォロー中投稿キャッシュ期限切れ")
            return nil
        }

        guard let data = userDefaults.data(forKey: CacheKeys.followingPosts) else {
            logger.debug("フォロー中投稿キャッシュなし")
            return nil
        }

        do {
            let posts = try JSONDecoder().decode([Post].self, from: data)
            logger.debug("フォロー中投稿をキャッシュから取得: \(posts.count)件")
            return posts
        } catch {
            logger.logError(error, context: "DecodeCacheFollowingPosts")
            return nil
        }
    }

    func cacheReactions(_ reactions: [Int: PostReactions]) {
        do {
            let data = try JSONEncoder().encode(reactions)
            userDefaults.set(data, forKey: CacheKeys.reactions)
            logger.debug("リアクションをキャッシュ: \(reactions.count)件")
        } catch {
            logger.logError(error, context: "CacheReactions")
        }
    }

    func getCachedReactions() -> [Int: PostReactions] {
        guard let data = userDefaults.data(forKey: CacheKeys.reactions) else {
            return [:]
        }

        do {
            let reactions = try JSONDecoder().decode([Int: PostReactions].self, from: data)
            logger.debug("リアクションをキャッシュから取得: \(reactions.count)件")
            return reactions
        } catch {
            logger.logError(error, context: "DecodeCacheReactions")
            return [:]
        }
    }

    func cacheBookmarks(_ bookmarks: Set<Int>) {
        do {
            let data = try JSONEncoder().encode(bookmarks)
            userDefaults.set(data, forKey: CacheKeys.bookmarks)
            logger.debug("ブックマークをキャッシュ: \(bookmarks.count)件")
        } catch {
            logger.logError(error, context: "CacheBookmarks")
        }
    }

    func getCachedBookmarks() -> Set<Int> {
        guard let data = userDefaults.data(forKey: CacheKeys.bookmarks) else {
            return Set<Int>()
        }

        do {
            let bookmarks = try JSONDecoder().decode(Set<Int>.self, from: data)
            logger.debug("ブックマークをキャッシュから取得: \(bookmarks.count)件")
            return bookmarks
        } catch {
            logger.logError(error, context: "DecodeCacheBookmarks")
            return Set<Int>()
        }
    }

    private func isCacheValid(timestampKey: String) -> Bool {
        let timestamp = userDefaults.double(forKey: timestampKey)
        guard timestamp > 0 else { return false }

        let cacheDate = Date(timeIntervalSince1970: timestamp)
        let now = Date()

        return now.timeIntervalSince(cacheDate) < cacheExpirationInterval
    }

    func clearAllCache() {
        let keys = [
            CacheKeys.allPosts,
            CacheKeys.allPostsTimestamp,
            CacheKeys.followingPosts,
            CacheKeys.followingPostsTimestamp,
            CacheKeys.reactions,
            CacheKeys.bookmarks
        ]

        for key in keys {
            userDefaults.removeObject(forKey: key)
        }

        clearMunicipalityCache()

        logger.info("全キャッシュをクリア")
    }

    func clearMunicipalityCache() {
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        let municipalityKeys = allKeys.filter {
            $0.hasPrefix(CacheKeys.municipalityPosts) ||
                $0.hasPrefix(CacheKeys.municipalityPostsTimestamp)
        }

        for key in municipalityKeys {
            userDefaults.removeObject(forKey: key)
        }

        logger.info("市町村キャッシュをクリア")
    }

    func getCacheInfo() -> (totalSize: Int, itemCount: Int, lastUpdated: Date?) {
        var totalSize = 0
        var itemCount = 0
        var lastUpdated: Date?

        let keys = [
            CacheKeys.allPosts,
            CacheKeys.followingPosts,
            CacheKeys.reactions,
            CacheKeys.bookmarks
        ]

        for key in keys {
            if let data = userDefaults.data(forKey: key) {
                totalSize += data.count
                itemCount += 1
            }
        }

        let timestamps = [
            userDefaults.double(forKey: CacheKeys.allPostsTimestamp),
            userDefaults.double(forKey: CacheKeys.followingPostsTimestamp)
        ].compactMap { $0 > 0 ? Date(timeIntervalSince1970: $0) : nil }

        if let latest = timestamps.max() {
            lastUpdated = latest
        }

        return (totalSize: totalSize, itemCount: itemCount, lastUpdated: lastUpdated)
    }
}

extension PostAPIService {
    func fetchAllPostsWithCache(page: Int = 1, limit: Int = 20, useCache: Bool = true) async throws -> [Post] {
        let isConnected = await NetworkMonitor.shared.isConnected

        if useCache, !isConnected || page == 1 {
            if let cachedPosts = PostCacheManager.shared.getCachedAllPosts() {
                return Array(cachedPosts.prefix(limit))
            }
        }

        do {
            let posts = try await fetchAllPosts(page: page, limit: limit)

            if page == 1 {
                PostCacheManager.shared.cacheAllPosts(posts)
            }

            return posts
        } catch {
            if let cachedPosts = PostCacheManager.shared.getCachedAllPosts() {
                print("📦 ネットワークエラー、キャッシュから取得")
                return Array(cachedPosts.prefix(limit))
            }
            throw error
        }
    }

    func fetchMunicipalityPostsWithCache(
        municipality: String,
        page: Int = 1,
        limit: Int = 20,
        useCache: Bool = true
    ) async throws -> [Post] {
        let isConnected = await NetworkMonitor.shared.isConnected

        if useCache, !isConnected || page == 1 {
            if let cachedPosts = PostCacheManager.shared.getCachedMunicipalityPosts(municipality: municipality) {
                return Array(cachedPosts.prefix(limit))
            }
        }

        do {
            let posts = try await fetchMunicipalityPosts(municipality: municipality, page: page, limit: limit)

            if page == 1 {
                PostCacheManager.shared.cacheMunicipalityPosts(posts, municipality: municipality)
            }

            return posts
        } catch {
            if let cachedPosts = PostCacheManager.shared.getCachedMunicipalityPosts(municipality: municipality) {
                print("📦 ネットワークエラー、キャッシュから取得 (\(municipality))")
                return Array(cachedPosts.prefix(limit))
            }
            throw error
        }
    }

    func fetchFollowingPostsWithCache(page: Int = 1, limit: Int = 20, useCache: Bool = true) async throws -> [Post] {
        let isConnected = await NetworkMonitor.shared.isConnected

        if useCache, !isConnected || page == 1 {
            if let cachedPosts = PostCacheManager.shared.getCachedFollowingPosts() {
                return Array(cachedPosts.prefix(limit))
            }
        }

        do {
            let posts = try await fetchFollowingPosts(page: page, limit: limit)

            if page == 1 {
                PostCacheManager.shared.cacheFollowingPosts(posts)
            }

            return posts
        } catch {
            if let cachedPosts = PostCacheManager.shared.getCachedFollowingPosts() {
                print("📦 ネットワークエラー、キャッシュから取得 (フォロー中)")
                return Array(cachedPosts.prefix(limit))
            }
            throw error
        }
    }
}
