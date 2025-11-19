import Foundation
import Combine
import Observation

@MainActor
@Observable
class FavoritesManager {
    static let shared = FavoritesManager()

    var favoriteShops: [Shop] = []
    var favoriteIds: Set<Int> = []
    var isLoading = false
    var errorMessage: String? {
        didSet {
            NotificationCenter.default.post(name: .FavoritesErrorChanged, object: self, userInfo: ["errorMessage": errorMessage as Any])
        }
    }

    private let shopAPIService = ShopAPIService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        Task {
            await loadFavorites()
        }
    }


    func toggleFavorite(shop: Shop) async {
        let wasAlreadyFavorite = favoriteIds.contains(shop.id)

        if wasAlreadyFavorite {
            favoriteIds.remove(shop.id)
            favoriteShops.removeAll { $0.id == shop.id }
        } else {
            favoriteIds.insert(shop.id)
            favoriteShops.append(shop)
        }

        do {
            let response = try await shopAPIService.toggleFavorite(shopId: shop.id)

            if response.favorited != !wasAlreadyFavorite {
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

    func isFavorite(shopId: Int) -> Bool {
        return favoriteIds.contains(shopId)
    }

    func loadFavorites() async {
        isLoading = true
        errorMessage = nil

        if AuthTokenManager.shared.token == nil {
            print("🔑 認証トークンを取得します")
            print("🔑 現在の認証トークン: nil")
            favoriteShops.removeAll()
            favoriteIds.removeAll()
            isLoading = false
            return
        }

        do {
            let favorites = try await shopAPIService.fetchFavorites()

            favoriteShops = favorites.compactMap { $0.shop }
            favoriteIds = Set(favorites.map { $0.shopId })

            print("✅ Loaded \(favorites.count) favorites")
            #if DEBUG
            for f in favorites {
                print("🧩 [Favorites] favId=\(f.id) shopId=\(f.shopId) shopImage=\(f.shop?.imageUrl ?? "<nil>")")
            }
            #endif
        } catch {
            errorMessage = "お気に入りの読み込みに失敗しました: \(error.localizedDescription)"
            print("🚨 Failed to load favorites: \(error)")
        }

        isLoading = false
    }


    func refreshFavorites() async {
        await loadFavorites()
    }


    func clearFavorites() {
        favoriteShops.removeAll()
        favoriteIds.removeAll()
        errorMessage = nil
    }


    func getFavoriteShopsSorted() -> [Shop] {
        return favoriteShops.sorted { shop1, shop2 in
            guard let date1 = shop1.createdAt, let date2 = shop2.createdAt else {
                return false
            }
            return date1 > date2
        }
    }


    var favoriteCount: Int {
        return favoriteIds.count
    }


    var isEmpty: Bool {
        return favoriteIds.isEmpty
    }
}

extension Notification.Name {
    static let FavoritesErrorChanged = Notification.Name("FavoritesErrorChanged")
}
