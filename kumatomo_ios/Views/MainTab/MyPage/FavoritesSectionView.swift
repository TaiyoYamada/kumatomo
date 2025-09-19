import SwiftUI
import CoreLocation

struct FavoritesSectionView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var sheetDestination: SheetDestination?
    
    private let maxDisplayCount = 3 // Show only first 3 favorites in compact view
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.primaryOrange)
                        .font(.system(size: 18))
                    
                    Text("お気に入り")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !favoritesManager.isEmpty {
                    NavigationLink(value: RouterDestination.favoritesList) {
                        HStack(spacing: 4) {
                            Text("すべて見る")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.primaryOrange)
                    }
                    .accessibilityIdentifier("ViewAllFavoritesButton")
                }
            }
            .padding(.horizontal, 20)
            
            // Content
            if favoritesManager.isLoading {
                FavoritesCompactLoadingView()
            } else if favoritesManager.isEmpty {
                FavoritesCompactEmptyView()
            } else {
                FavoritesCompactListView(
                    shops: Array(favoritesManager.getFavoriteShopsSorted().prefix(maxDisplayCount)),
                    totalCount: favoritesManager.favoriteCount,
                    userLocation: locationManager.userLocation,
                    onShopTapped: { shop in
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        sheetDestination = .shopDetail(shop)
                    }
                )
            }
            
            // Error message
            if let errorMessage = favoritesManager.errorMessage {
                FavoritesCompactErrorView(
                    message: errorMessage,
                    onDismiss: {
                        favoritesManager.errorMessage = nil
                    },
                    onRetry: {
                        Task {
                            await favoritesManager.refreshFavorites()
                        }
                    }
                )
            }
        }
        .withSheetRouter(sheet: $sheetDestination)
        .onAppear {
            Task {
                await favoritesManager.loadFavorites()
            }
        }
    }
}

// MARK: - Favorites Compact List View
struct FavoritesCompactListView: View {
    let shops: [Shop]
    let totalCount: Int
    let userLocation: CLLocation?
    let onShopTapped: (Shop) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(shops) { shop in
                FavoritesCompactCardView(
                    shop: shop,
                    distance: distanceFromUser(shop),
                    onTap: { onShopTapped(shop) }
                )
                .accessibilityIdentifier("CompactFavoriteCard_\(shop.id)")
            }
            
            // Show count if there are more favorites
            if totalCount > shops.count {
                NavigationLink(value: RouterDestination.favoritesList) {
                    HStack {
                        Text("他 \(totalCount - shops.count) 件のお気に入り")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryOrange)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primaryOrange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.primaryOrange.opacity(0.05))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                .accessibilityIdentifier("ViewMoreFavoritesButton")
            }
        }
    }
    
    private func distanceFromUser(_ shop: Shop) -> String? {
        guard let userLocation = userLocation,
              let coordinate = shop.coordinate else { return nil }
        
        let shopLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = userLocation.distance(from: shopLocation)
        
        return LocationManager.formatDistance(distance)
    }
}

// MARK: - Favorites Compact Card View
struct FavoritesCompactCardView: View {
    let shop: Shop
    let distance: String?
    let onTap: () -> Void
    
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var isTogglingFavorite = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Shop image
                AsyncImage(url: URL(string: shop.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.title3)
                        )
                }
                .frame(width: 60, height: 60)
                .clipped()
                .cornerRadius(8)
                
                // Shop info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(shop.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let distance = distance {
                            Text(distance)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                    
                    if let genre = shop.genre {
                        Text(genre.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primaryOrange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primaryOrange.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if let address = shop.address {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.secondary)
                                .font(.system(size: 10))
                            Text(address)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                // Favorite button
                Button(action: {
                    Task {
                        await toggleFavorite()
                    }
                }) {
                    ZStack {
                        if isTogglingFavorite {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.primaryOrange)
                        } else {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.yellow)
                        }
                    }
                    .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier("CompactRemoveFavoriteButton_\(shop.id)")
                .accessibilityLabel("お気に入りから削除")
                .disabled(isTogglingFavorite)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
    
    private func toggleFavorite() async {
        isTogglingFavorite = true
        await favoritesManager.toggleFavorite(shop: shop)
        isTogglingFavorite = false
    }
}

// MARK: - Favorites Compact Loading View
struct FavoritesCompactLoadingView: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("お気に入りを読み込み中...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .accessibilityIdentifier("FavoritesCompactLoadingView")
    }
}

// MARK: - Favorites Compact Empty View
struct FavoritesCompactEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star")
                    .foregroundColor(.secondary)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("まだお気に入りがありません")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("気になるお店を⭐️でお気に入りに追加しましょう")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            NavigationLink(value: RouterDestination.shopList) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("お店を探す")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primaryOrange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primaryOrange.opacity(0.1))
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .accessibilityIdentifier("FavoritesCompactEmptyView")
    }
}

// MARK: - Favorites Compact Error View
struct FavoritesCompactErrorView: View {
    let message: String
    let onDismiss: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("お気に入りの読み込みに失敗")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button("再試行", action: onRetry)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primaryOrange)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .accessibilityIdentifier("FavoritesCompactErrorView")
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            FavoritesSectionView()
        }
    }
}