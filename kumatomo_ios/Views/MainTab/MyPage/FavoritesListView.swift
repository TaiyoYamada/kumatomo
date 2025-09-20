import SwiftUI
import CoreLocation

struct FavoritesListView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var sheetDestination: SheetDestination?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if favoritesManager.isLoading {
                    FavoritesLoadingView()
                } else if favoritesManager.isEmpty {
                    FavoritesEmptyStateView()
                } else {
                    FavoritesContentView(
                        shops: favoritesManager.getFavoriteShopsSorted(),
                        userLocation: locationManager.userLocation,
                        onShopTapped: { shop in
                            // Add haptic feedback for better UX
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            sheetDestination = .shopDetail(shop)
                        },
                        onRefresh: {
                            Task {
                                await favoritesManager.refreshFavorites()
                            }
                        }
                    )
                }
                
                // Error banner
                if let errorMessage = favoritesManager.errorMessage {
                    FavoritesErrorBanner(
                        message: errorMessage,
                        onDismiss: {
                            favoritesManager.errorMessage = nil
                        }
                    )
                }
            }
            .navigationTitle("お気に入り店舗")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await favoritesManager.refreshFavorites()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primaryOrange)
                    }
                    .disabled(favoritesManager.isLoading)
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
}

// MARK: - Favorites Content View
struct FavoritesContentView: View {
    let shops: [Shop]
    let userLocation: CLLocation?
    let onShopTapped: (Shop) -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(shops) { shop in
                    FavoriteShopCardView(
                        shop: shop,
                        distance: distanceFromUser(shop),
                        onTap: { onShopTapped(shop) }
                    )
                    .accessibilityIdentifier("FavoriteShopCard_\(shop.id)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable {
            onRefresh()
        }
        .accessibilityIdentifier("FavoritesScrollView")
    }
    
    private func distanceFromUser(_ shop: Shop) -> String? {
        guard let userLocation = userLocation,
              let coordinate = shop.coordinate else { return nil }
        
        let shopLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = userLocation.distance(from: shopLocation)
        
        return LocationManager.formatDistance(distance)
    }
}

// MARK: - Favorite Shop Card View
struct FavoriteShopCardView: View {
    let shop: Shop
    let distance: String?
    let onTap: () -> Void
    
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var isTogglingFavorite = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 店舗画像 with favorite button overlay
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: ImageURLNormalizer.normalize(shop.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.title)
                            )
                    }
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(12)
                    .onAppear {
                        #if DEBUG
                        ImageDebugLogger.logImage(shop.imageUrl, context: "FavoritesList:shopId=\(shop.id)")
                        #endif
                    }
                    
                    // Favorite star button - always filled since this is favorites list
                    Button(action: {
                        Task {
                            await toggleFavorite()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 36, height: 36)
                            
                            if isTogglingFavorite {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(12)
                    .accessibilityIdentifier("RemoveFavoriteButton_\(shop.id)")
                    .accessibilityLabel("お気に入りから削除")
                    .disabled(isTogglingFavorite)
                }
                
                // 店舗情報
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(shop.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let distance = distance {
                            Text(distance)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    if let genre = shop.genre {
                        Text(genre.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primaryOrange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primaryOrange.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    if let address = shop.address {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            Text(address)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    if let description = shop.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Show Try特典 badge if available
                    if shop.hasTryBenefit {
                        HStack {
                            Image(systemName: "gift")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("Try特典あり")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(ShopCardButtonStyle())
    }
    
    private func toggleFavorite() async {
        isTogglingFavorite = true
        await favoritesManager.toggleFavorite(shop: shop)
        isTogglingFavorite = false
    }
}

// MARK: - Favorites Loading View
struct FavoritesLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("お気に入りを読み込み中...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("FavoritesLoadingView")
    }
}

// MARK: - Favorites Empty State View
struct FavoritesEmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.primaryOrange.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "star")
                    .font(.system(size: 40))
                    .foregroundColor(.primaryOrange)
            }
            
            // Message
            VStack(spacing: 12) {
                Text("お気に入りがありません")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("気になるお店を見つけたら、\n⭐️ボタンでお気に入りに追加しましょう")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Action button
            NavigationLink(value: RouterDestination.shopList) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("お店を探す")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.primaryOrange)
                .cornerRadius(25)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("FavoritesEmptyStateView")
    }
}

#Preview {
    FavoritesListView()
}
