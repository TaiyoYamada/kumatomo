import Foundation

class PostCacheManager: ObservableObject {
    static let shared = PostCacheManager()
    
    private let userDefaults = UserDefaults.standard
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    // Cache keys
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
    
    // MARK: - Post Caching
    
    func cacheAllPosts(_ posts: [Post]) {
        do {
            let data = try JSONEncoder().encode(posts)
            userDefaults.set(data, forKey: CacheKeys.allPosts)
            userDefaults.set(Date().timeIntervalSince1970, forKey: CacheKeys.allPostsTimestamp)
            print("📦 全投稿をキャッシュしました: \(posts.count)件")
        } catch {
            print("🚨 全投稿のキャッシュに失敗: \(error)")
        }
    }
    
    func getCachedAllPosts() -> [Post]? {
        guard isCacheValid(timestampKey: CacheKeys.allPostsTimestamp) else {
            print("📦 全投稿のキャッシュが期限切れです")
            return nil
        }
        
        guard let data = userDefaults.data(forKey: CacheKeys.allPosts) else {
            print("📦 全投稿のキャッシュが見つかりません")
            return nil
        }
        
        do {
            let posts = try JSONDecoder().decode([Post].self, from: data)
            print("📦 全投稿をキャッシュから取得: \(posts.count)件")
            return posts
        } catch {
            print("🚨 全投稿のキャッシュデコードに失敗: \(error)")
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
            print("📦 市町村投稿をキャッシュしました (\(municipality)): \(posts.count)件")
        } catch {
            print("🚨 市町村投稿のキャッシュに失敗 (\(municipality)): \(error)")
        }
    }
    
    func getCachedMunicipalityPosts(municipality: String) -> [Post]? {
        let timestampKey = CacheKeys.municipalityPostsTimestamp + municipality
        guard isCacheValid(timestampKey: timestampKey) else {
            print("📦 市町村投稿のキャッシュが期限切れです (\(municipality))")
            return nil
        }
        
        let key = CacheKeys.municipalityPosts + municipality
        guard let data = userDefaults.data(forKey: key) else {
            print("📦 市町村投稿のキャッシュが見つかりません (\(municipality))")
            return nil
        }
        
        do {
            let posts = try JSONDecoder().decode([Post].self, from: data)
            print("📦 市町村投稿をキャッシュから取得 (\(municipality)): \(posts.count)件")
            return posts
        } catch {
            print("🚨 市町村投稿のキャッシュデコードに失敗 (\(municipality)): \(error)")
            return nil
        }
    }
    
    func cacheFollowingPosts(_ posts: [Post]) {
        do {
            let data = try JSONEncoder().encode(posts)
            userDefaults.set(data, forKey: CacheKeys.followingPosts)
            userDefaults.set(Date().timeIntervalSince1970, forKey: CacheKeys.followingPostsTimestamp)
            print("📦 フォロー中投稿をキャッシュしました: \(posts.count)件")
        } catch {
            print("🚨 フォロー中投稿のキャッシュに失敗: \(error)")
        }
    }
    
    func getCachedFollowingPosts() -> [Post]? {
        guard isCacheValid(timestampKey: CacheKeys.followingPostsTimestamp) else {
            print("📦 フォロー中投稿のキャッシュが期限切れです")
            return nil
        }
        
        guard let data = userDefaults.data(forKey: CacheKeys.followingPosts) else {
            print("📦 フォロー中投稿のキャッシュが見つかりません")
            return nil
        }
        
        do {
            let posts = try JSONDecoder().decode([Post].self, from: data)
            print("📦 フォロー中投稿をキャッシュから取得: \(posts.count)件")
            return posts
        } catch {
            print("🚨 フォロー中投稿のキャッシュデコードに失敗: \(error)")
            return nil
        }
    }
    
    // MARK: - Reaction and Bookmark Caching
    
    func cacheReactions(_ reactions: [Int: PostReactions]) {
        do {
            let data = try JSONEncoder().encode(reactions)
            userDefaults.set(data, forKey: CacheKeys.reactions)
            print("📦 リアクションをキャッシュしました: \(reactions.count)件")
        } catch {
            print("🚨 リアクションのキャッシュに失敗: \(error)")
        }
    }
    
    func getCachedReactions() -> [Int: PostReactions] {
        guard let data = userDefaults.data(forKey: CacheKeys.reactions) else {
            return [:]
        }
        
        do {
            let reactions = try JSONDecoder().decode([Int: PostReactions].self, from: data)
            print("📦 リアクションをキャッシュから取得: \(reactions.count)件")
            return reactions
        } catch {
            print("🚨 リアクションのキャッシュデコードに失敗: \(error)")
            return [:]
        }
    }
    
    func cacheBookmarks(_ bookmarks: Set<Int>) {
        do {
            let data = try JSONEncoder().encode(bookmarks)
            userDefaults.set(data, forKey: CacheKeys.bookmarks)
            print("📦 ブックマークをキャッシュしました: \(bookmarks.count)件")
        } catch {
            print("🚨 ブックマークのキャッシュに失敗: \(error)")
        }
    }
    
    func getCachedBookmarks() -> Set<Int> {
        guard let data = userDefaults.data(forKey: CacheKeys.bookmarks) else {
            return Set<Int>()
        }
        
        do {
            let bookmarks = try JSONDecoder().decode(Set<Int>.self, from: data)
            print("📦 ブックマークをキャッシュから取得: \(bookmarks.count)件")
            return bookmarks
        } catch {
            print("🚨 ブックマークのキャッシュデコードに失敗: \(error)")
            return Set<Int>()
        }
    }
    
    // MARK: - Cache Management
    
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
        
        // Clear municipality-specific caches
        clearMunicipalityCache()
        
        print("📦 全キャッシュをクリアしました")
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
        
        print("📦 市町村キャッシュをクリアしました")
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
        
        // Check timestamps
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

// MARK: - Cache-aware API Extensions

extension PostAPIService {
    func fetchAllPostsWithCache(page: Int = 1, limit: Int = 20, useCache: Bool = true) async throws -> [Post] {
        // Check network status on main actor
        let isConnected = await NetworkMonitor.shared.isConnected
        
        // Try cache first if offline or cache requested
        if useCache && (!isConnected || page == 1) {
            if let cachedPosts = PostCacheManager.shared.getCachedAllPosts() {
                return Array(cachedPosts.prefix(limit))
            }
        }
        
        // Fetch from network
        do {
            let posts = try await fetchAllPosts(page: page, limit: limit)
            
            // Cache the first page
            if page == 1 {
                PostCacheManager.shared.cacheAllPosts(posts)
            }
            
            return posts
        } catch {
            // Fallback to cache if network fails
            if let cachedPosts = PostCacheManager.shared.getCachedAllPosts() {
                print("📦 ネットワークエラー、キャッシュから取得")
                return Array(cachedPosts.prefix(limit))
            }
            throw error
        }
    }
    
    func fetchMunicipalityPostsWithCache(municipality: String, page: Int = 1, limit: Int = 20, useCache: Bool = true) async throws -> [Post] {
        // Check network status on main actor
        let isConnected = await NetworkMonitor.shared.isConnected
        
        // Try cache first if offline or cache requested
        if useCache && (!isConnected || page == 1) {
            if let cachedPosts = PostCacheManager.shared.getCachedMunicipalityPosts(municipality: municipality) {
                return Array(cachedPosts.prefix(limit))
            }
        }
        
        // Fetch from network
        do {
            let posts = try await fetchMunicipalityPosts(municipality: municipality, page: page, limit: limit)
            
            // Cache the first page
            if page == 1 {
                PostCacheManager.shared.cacheMunicipalityPosts(posts, municipality: municipality)
            }
            
            return posts
        } catch {
            // Fallback to cache if network fails
            if let cachedPosts = PostCacheManager.shared.getCachedMunicipalityPosts(municipality: municipality) {
                print("📦 ネットワークエラー、キャッシュから取得 (\(municipality))")
                return Array(cachedPosts.prefix(limit))
            }
            throw error
        }
    }
    
    func fetchFollowingPostsWithCache(page: Int = 1, limit: Int = 20, useCache: Bool = true) async throws -> [Post] {
        // Check network status on main actor
        let isConnected = await NetworkMonitor.shared.isConnected
        
        // Try cache first if offline or cache requested
        if useCache && (!isConnected || page == 1) {
            if let cachedPosts = PostCacheManager.shared.getCachedFollowingPosts() {
                return Array(cachedPosts.prefix(limit))
            }
        }
        
        // Fetch from network
        do {
            let posts = try await fetchFollowingPosts(page: page, limit: limit)
            
            // Cache the first page
            if page == 1 {
                PostCacheManager.shared.cacheFollowingPosts(posts)
            }
            
            return posts
        } catch {
            // Fallback to cache if network fails
            if let cachedPosts = PostCacheManager.shared.getCachedFollowingPosts() {
                print("📦 ネットワークエラー、キャッシュから取得 (フォロー中)")
                return Array(cachedPosts.prefix(limit))
            }
            throw error
        }
    }
}