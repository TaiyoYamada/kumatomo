import Foundation
import CoreLocation
import Combine

/// LocationManager service for handling CoreLocation integration with proper permission handling and graceful degradation
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    // MARK: - Published Properties
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled: Bool = false
    @Published var locationError: LocationError?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var locationUpdateCompletion: ((Result<CLLocation, LocationError>) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    
    /// Requests location permission and starts location updates if granted
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = .permissionDenied
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            locationError = .unknown
        }
    }
    
    /// Starts location updates if permission is granted
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = .permissionDenied
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = .locationServicesDisabled
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
        locationError = nil
    }
    
    /// Stops location updates
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    /// Requests a one-time location update
    func requestOneTimeLocation(completion: @escaping (Result<CLLocation, LocationError>) -> Void) {
        locationUpdateCompletion = completion
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            completion(.failure(.permissionDenied))
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.failure(.locationServicesDisabled))
            return
        }
        
        locationManager.requestLocation()
    }
    
    /// Calculates distance between two coordinates
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    /// Formats distance with proper unit formatting (meters/kilometers)
    static func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    /// Calculates and formats distance from user location to a coordinate
    func distanceFromUser(to coordinate: CLLocationCoordinate2D) -> String? {
        guard let userLocation = userLocation else { return nil }
        
        let distance = self.distance(from: userLocation.coordinate, to: coordinate)
        return LocationManager.formatDistance(distance)
    }
    
    /// Calculates and formats distance from user location to a shop
    func distanceFromUser(to shop: Shop) -> String? {
        guard let coordinate = shop.coordinate else { return nil }
        return distanceFromUser(to: coordinate)
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        authorizationStatus = locationManager.authorizationStatus
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out old or inaccurate locations
        let locationAge = -location.timestamp.timeIntervalSinceNow
        guard locationAge < 5.0 && location.horizontalAccuracy < 100 else { return }
        
        userLocation = location
        locationError = nil
        
        // Complete one-time location request if pending
        if let completion = locationUpdateCompletion {
            completion(.success(location))
            locationUpdateCompletion = nil
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let locationError: LocationError
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .permissionDenied
            case .locationUnknown:
                locationError = .locationUnavailable
            case .network:
                locationError = .networkError
            default:
                locationError = .unknown
            }
        } else {
            locationError = .unknown
        }
        
        self.locationError = locationError
        
        // Complete one-time location request with error if pending
        if let completion = locationUpdateCompletion {
            completion(.failure(locationError))
            locationUpdateCompletion = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
            locationError = .permissionDenied
        case .notDetermined:
            locationError = nil
        @unknown default:
            locationError = .unknown
        }
    }
}

// MARK: - LocationError
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationServicesDisabled
    case locationUnavailable
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "位置情報の使用が許可されていません。設定から許可してください。"
        case .locationServicesDisabled:
            return "位置情報サービスが無効になっています。設定から有効にしてください。"
        case .locationUnavailable:
            return "現在位置を取得できませんでした。しばらく待ってから再試行してください。"
        case .networkError:
            return "ネットワークエラーにより位置情報を取得できませんでした。"
        case .unknown:
            return "位置情報の取得中に予期しないエラーが発生しました。"
        }
    }
}