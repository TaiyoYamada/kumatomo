import Foundation
import CoreLocation
import SwiftUI

@MainActor
class ShopListViewModel: ObservableObject {
    @Published var shops: [Shop] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedGenre: String? = nil
    @Published var showingMap = false
    @Published var userLocation: CLLocation?
    
    private let shopAPIService = ShopAPIService.shared
    private let locationManager = CLLocationManager()
    private var locationDelegate: LocationDelegate?
    
    // ジャンル一覧（フィルタリング用）
    let genres = ["すべて", "カフェ", "レストラン", "居酒屋", "ファストフード", "スイーツ", "その他"]
    
    init() {
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationDelegate = LocationDelegate(viewModel: self)
        locationManager.delegate = locationDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func loadShops() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let genre = selectedGenre == "すべて" ? nil : selectedGenre
            let latitude = userLocation?.coordinate.latitude
            let longitude = userLocation?.coordinate.longitude
            
            shops = try await shopAPIService.fetchShops(
                genre: genre,
                latitude: latitude,
                longitude: longitude,
                radius: 5000 // 5km radius
            )
        } catch {
            errorMessage = error.localizedDescription
            print("🚨 お店一覧の取得に失敗: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshShops() async {
        await loadShops()
    }
    
    func selectGenre(_ genre: String) {
        selectedGenre = genre
        Task {
            await loadShops()
        }
    }
    
    func toggleMapView() {
        showingMap.toggle()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func distanceFromUser(to shop: Shop) -> String? {
        guard let userLocation = userLocation,
              let shopLat = shop.latitude,
              let shopLng = shop.longitude else {
            return nil
        }
        
        let shopLocation = CLLocation(latitude: shopLat, longitude: shopLng)
        let distance = userLocation.distance(from: shopLocation)
        
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// Location Manager Delegate
class LocationDelegate: NSObject, CLLocationManagerDelegate {
    weak var viewModel: ShopListViewModel?
    
    init(viewModel: ShopListViewModel) {
        self.viewModel = viewModel
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            viewModel?.userLocation = location
            manager.stopUpdatingLocation()
            await viewModel?.loadShops()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("🚨 位置情報の取得に失敗: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("🚨 位置情報の許可が拒否されました")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}