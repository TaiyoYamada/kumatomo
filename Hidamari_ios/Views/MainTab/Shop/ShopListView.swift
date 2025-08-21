import SwiftUI
import MapKit

struct ShopListView: View {
    @StateObject private var viewModel = ShopListViewModel()
    @State private var sheetDestination: SheetDestination?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ジャンルフィルター
                GenreFilterView(
                    genres: viewModel.genres,
                    selectedGenre: viewModel.selectedGenre ?? "すべて",
                    onGenreSelected: { genre in
                        viewModel.selectGenre(genre)
                    }
                )
                
                // マップ/リスト切り替えボタン
                ViewToggleButtons(
                    showingMap: viewModel.showingMap,
                    onToggle: viewModel.toggleMapView
                )
                
                // メインコンテンツ
                if viewModel.showingMap {
                    ShopMapView(
                        shops: viewModel.shops,
                        userLocation: viewModel.userLocation,
                        onShopSelected: { shop in
                            sheetDestination = .shopDetail(shop)
                        }
                    )
                } else {
                    ShopListContentView(
                        shops: viewModel.shops,
                        isLoading: viewModel.isLoading,
                        errorMessage: viewModel.errorMessage,
                        userLocation: viewModel.userLocation,
                        onRefresh: {
                            Task {
                                await viewModel.refreshShops()
                            }
                        },
                        onShopTapped: { shop in
                            sheetDestination = .shopDetail(shop)
                        },
                        distanceFromUser: viewModel.distanceFromUser
                    )
                }
            }
            .navigationTitle("お店一覧")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(value: RouterDestination.search) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("検索")
                    .accessibilityHint("お店や投稿を検索")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.requestLocationPermission) {
                        Image(systemName: "location")
                            .foregroundColor(.pink)
                    }
                    .accessibilityLabel("位置情報")
                    .accessibilityHint("現在地を取得")
                }
            }
            .withSheetRouter(sheet: $sheetDestination)
            .withAppRouter()
        }
    }
}

// MARK: - Genre Filter View
struct GenreFilterView: View {
    let genres: [String]
    let selectedGenre: String
    let onGenreSelected: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(genres, id: \.self) { genre in
                    GenreChip(
                        title: genre,
                        isSelected: genre == selectedGenre,
                        onTap: { onGenreSelected(genre) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

struct GenreChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.pink : Color(.systemGray6))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Toggle Buttons
struct ViewToggleButtons: View {
    let showingMap: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("リスト")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(showingMap ? .secondary : .pink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Rectangle()
                        .fill(showingMap ? Color.clear : Color.pink.opacity(0.1))
                )
            }
            
            Button(action: onToggle) {
                HStack {
                    Image(systemName: "map")
                    Text("マップ")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(showingMap ? .pink : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Rectangle()
                        .fill(showingMap ? Color.pink.opacity(0.1) : Color.clear)
                )
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Shop List Content View
struct ShopListContentView: View {
    let shops: [Shop]
    let isLoading: Bool
    let errorMessage: String?
    let userLocation: CLLocation?
    let onRefresh: () -> Void
    let onShopTapped: (Shop) -> Void
    let distanceFromUser: (Shop) -> String?
    
    var body: some View {
        if isLoading && shops.isEmpty {
            LoadingView()
        } else if let errorMessage = errorMessage, shops.isEmpty {
            ShopErrorView(message: errorMessage, onRetry: onRefresh)
        } else {
            RefreshableScrollView(onRefresh: onRefresh) {
                LazyVStack(spacing: 16) {
                    ForEach(shops) { shop in
                        ShopCardView(
                            shop: shop,
                            distance: distanceFromUser(shop),
                            onTap: { onShopTapped(shop) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Shop Card View
struct ShopCardView: View {
    let shop: Shop
    let distance: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 店舗画像
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
                                .font(.title)
                        )
                }
                .frame(height: 160)
                .clipped()
                .cornerRadius(12)
                
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
                        Text(genre)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.pink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.pink.opacity(0.1))
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
                }
                .padding(.horizontal, 4)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("お店を読み込み中...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Shop Error View
struct ShopErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("エラーが発生しました")
                .font(.system(size: 18, weight: .semibold))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("再試行", action: onRetry)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.pink)
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Refreshable Scroll View
struct RefreshableScrollView<Content: View>: View {
    let onRefresh: () -> Void
    let content: Content
    
    init(onRefresh: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
        }
        .refreshable {
            onRefresh()
        }
    }
}
