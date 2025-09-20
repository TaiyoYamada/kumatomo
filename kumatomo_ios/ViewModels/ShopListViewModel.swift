import Foundation
import CoreLocation
import SwiftUI
import Combine

@MainActor
class ShopListViewModel: ObservableObject {
    @Published var shops: [Shop] = []
    @Published var filteredShops: [Shop] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedGenres: Set<ShopGenre> = []
    @Published var showingMap = false
    @Published var favoritesErrorMessage: String?
    @Published var selectedShop: Shop?
    
    private let shopAPIService = ShopAPIService.shared
    private let locationManager = LocationManager.shared
    private let favoritesManager = FavoritesManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Computed property to access user location from LocationManager
    var userLocation: CLLocation? {
        return locationManager.userLocation
    }
    
    init() {
        // Request location permission on initialization
        locationManager.requestLocationPermission()
        
        // Observe location updates and reload shops when location is available
        locationManager.$userLocation
            .compactMap { $0 }
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadShops()
                }
            }
            .store(in: &cancellables)
        
        // Observe favorites manager errors
        favoritesManager.$errorMessage
            .sink { [weak self] errorMessage in
                self?.favoritesErrorMessage = errorMessage
            }
            .store(in: &cancellables)
        
        // Load initial data
        Task {
            await loadShops()
        }
    }
    
    func loadShops() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let latitude = userLocation?.coordinate.latitude
            let longitude = userLocation?.coordinate.longitude
            
            shops = try await shopAPIService.fetchShops(
                genre: nil, // Load all shops, filter locally for multi-select
                latitude: latitude,
                longitude: longitude,
                radius: 5000 // 5km radius
            )
            
            applyFilters()
            #if DEBUG
            print("🧩 [ShopListVM] fetched shops count=\(shops.count)")
            for s in shops { print("🧩 [ShopListVM] id=\(s.id) name=\(s.name) imageUrl=\(s.imageUrl ?? "<nil>")") }
            #endif
        } catch {
            // 開発環境でAPIが利用できない場合はモックデータを使用
            if !APIConfig.shared.isConfigured || error.localizedDescription.contains("localhost") {
                print("🔧 APIが利用できないため、モックデータを使用します")
                shops = createMockShops()
                applyFilters()
            } else {
                errorMessage = error.localizedDescription
                print("🚨 お店一覧の取得に失敗: \(error)")
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Mock Data for Development
    private func createMockShops() -> [Shop] {
        return [
            Shop(
                id: 1,
                name: "熊本ラーメン 桂花",
                description: "熊本の老舗ラーメン店。マー油が香る豚骨ラーメンが自慢です。",
                address: "熊本県熊本市中央区花畑町11-9",
                phone: "096-325-9609",
                businessHours: "11:00-21:00",
                genre: .restaurant,
                latitude: 32.8031,
                longitude: 130.7079,
                imageUrl: nil
            ),
            Shop(
                id: 2,
                name: "熊本城",
                description: "日本三名城の一つ。加藤清正が築いた名城で、熊本のシンボルです。",
                address: "熊本県熊本市中央区本丸1-1",
                phone: "096-352-5900",
                businessHours: "9:00-17:00",
                genre: .other,
                latitude: 32.8064,
                longitude: 130.7056,
                imageUrl: nil
            ),
            Shop(
                id: 3,
                name: "水前寺成趣園",
                description: "桃山式回遊庭園。富士山を模した築山と湧水池が美しい庭園です。",
                address: "熊本県熊本市中央区水前寺公園8-1",
                phone: "096-383-0074",
                businessHours: "7:30-18:00",
                genre: .other,
                latitude: 32.7890,
                longitude: 130.7420,
                imageUrl: nil
            ),
            Shop(
                id: 4,
                name: "阿蘇ファームランド",
                description: "阿蘇の大自然の中で体験できるテーマパーク。健康と癒しがテーマです。",
                address: "熊本県阿蘇郡南阿蘇村河陽5579-3",
                phone: "0967-67-2100",
                businessHours: "9:00-17:00",
                genre: .other,
                latitude: 32.8500,
                longitude: 131.0500,
                imageUrl: nil
            ),
            Shop(
                id: 5,
                name: "馬刺し専門店 菅乃屋",
                description: "熊本名物の馬刺しを味わえる専門店。新鮮な馬肉を提供しています。",
                address: "熊本県熊本市中央区上通町6-17",
                phone: "096-351-0529",
                businessHours: "17:00-24:00",
                genre: .restaurant,
                latitude: 32.8100,
                longitude: 130.7100,
                imageUrl: nil
            )
        ]
    }
    
    func refreshShops() async {
        await loadShops()
    }
    
    func toggleGenre(_ genre: ShopGenre) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
        applyFilters()
    }
    
    func clearAllGenres() {
        selectedGenres.removeAll()
        applyFilters()
    }
    
    func applyFilters() {
        if selectedGenres.isEmpty {
            filteredShops = shops
        } else {
            filteredShops = shops.filter { shop in
                guard let shopGenre = shop.genre else { return false }
                return selectedGenres.contains(shopGenre)
            }
        }
    }
    
    func toggleMapView() {
        showingMap.toggle()
    }
    
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
    
    func distanceFromUser(to shop: Shop) -> String? {
        return locationManager.distanceFromUser(to: shop)
    }
    
    func dismissFavoritesError() {
        favoritesErrorMessage = nil
        favoritesManager.errorMessage = nil
    }
    
    func selectShopFromMap(_ shop: Shop) {
        selectedShop = shop
        
        // If we're in list view, scroll to the selected shop
        if !showingMap {
            // This would require additional implementation in the list view
            // to handle scrolling to a specific shop
        }
    }
    
    func clearSelection() {
        selectedShop = nil
    }
}
