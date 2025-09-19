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
        } catch {
            errorMessage = error.localizedDescription
            print("🚨 お店一覧の取得に失敗: \(error)")
        }
        
        isLoading = false
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

