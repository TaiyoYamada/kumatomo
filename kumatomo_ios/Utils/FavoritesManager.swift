import Foundation
import Combine

@MainActor
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favoriteShops: [Shop] = []
    @Published var favoriteIds: Set<Int> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let shopAPIService = ShopAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load favorites on initialization
        Task {
            await loadFavorites()
        }
    }
    
    // MARK: - Public Methods
    
    /// Toggle favorite status for a shop
    func toggleFavorite(shop: Shop) async {
        let wasAlreadyFavorite = favoriteIds.contains(shop.id)
        
        // Optimistic update
        if wasAlreadyFavorite {
            favoriteIds.remove(shop.id)
            favoriteShops.removeAll { $0.id == shop.id }
        } else {
            favoriteIds.insert(shop.id)
            favoriteShops.append(shop)
        }
        
        do {
            let response = try await shopAPIService.toggleFavorite(shopId: shop.id)
            
            // Verify the server response matches our optimistic update
            if response.favorited != !wasAlreadyFavorite {
                // Revert optimistic update if server response doesn't match
                if wasAlreadyFavorite {
                    favoriteIds.insert(shop.id)
                    favoriteShops.append(shop)
                } else {
                    favoriteIds.remove(shop.id)
                    favoriteShops.removeAll { $0.id == shop.id }
                }
            }
            
            errorMessage = nil
        } catch {
            // Revert optimistic update on error
            if wasAlreadyFavorite {
                favoriteIds.insert(shop.id)
                favoriteShops.append(shop)
            } else {
                favoriteIds.remove(shop.id)
                favoriteShops.removeAll { $0.id == shop.id }
            }
            
            errorMessage = "お気に入りの更新に失敗しました: \(error.localizedDescription)"
            print("🚨 Failed to toggle favorite: \(error)")
        }
    }
    
    /// Check if a shop is favorited
    func isFavorite(shopId: Int) -> Bool {
        return favoriteIds.contains(shopId)
    }
    
    /// Load user's favorite shops from the server
    func loadFavorites() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let favorites = try await shopAPIService.fetchFavorites()
            
            // Update state with fetched data
            favoriteShops = favorites.compactMap { $0.shop }
            favoriteIds = Set(favorites.map { $0.shopId })
            
            print("✅ Loaded \(favorites.count) favorites")
        } catch {
            errorMessage = "お気に入りの読み込みに失敗しました: \(error.localizedDescription)"
            print("🚨 Failed to load favorites: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh favorites from server
    func refreshFavorites() async {
        await loadFavorites()
    }
    
    /// Clear all favorites (for logout scenarios)
    func clearFavorites() {
        favoriteShops.removeAll()
        favoriteIds.removeAll()
        errorMessage = nil
    }
    
    /// Get favorite shops sorted by creation date (newest first)
    func getFavoriteShopsSorted() -> [Shop] {
        return favoriteShops.sorted { shop1, shop2 in
            guard let date1 = shop1.createdAt, let date2 = shop2.createdAt else {
                return false
            }
            return date1 > date2
        }
    }
    
    /// Get favorite count
    var favoriteCount: Int {
        return favoriteIds.count
    }
    
    /// Check if favorites are empty
    var isEmpty: Bool {
        return favoriteIds.isEmpty
    }
}

