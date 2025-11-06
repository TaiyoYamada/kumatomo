import Foundation
import CoreLocation
import Combine
import Observation


@MainActor
@Observable
class LocationManager: NSObject {
    static let shared = LocationManager()

    var userLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isLocationEnabled: Bool = false
    var locationError: LocationError?

    private let locationManager = CLLocationManager()
    private var locationUpdateCompletion: ((Result<CLLocation, LocationError>) -> Void)?

    override init() {
        super.init()
        setupLocationManager()
    }



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
        NotificationCenter.default.post(name: .LocationAuthorizationChanged, object: self, userInfo: ["status": authorizationStatus])
    }


    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }


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


    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }


    static func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }


    func distanceFromUser(to coordinate: CLLocationCoordinate2D) -> String? {
        guard let userLocation = userLocation else { return nil }

        let distance = self.distance(from: userLocation.coordinate, to: coordinate)
        return LocationManager.formatDistance(distance)
    }

    func distanceFromUser(to shop: Shop) -> String? {
        guard let coordinate = shop.coordinate else { return nil }
        return distanceFromUser(to: coordinate)
    }


    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        authorizationStatus = locationManager.authorizationStatus
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let locationAge = -location.timestamp.timeIntervalSinceNow
        guard locationAge < 5.0 && location.horizontalAccuracy < 100 else { return }

        userLocation = location
        locationError = nil
        NotificationCenter.default.post(name: .LocationUpdated, object: self, userInfo: ["userLocation": location])

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
        NotificationCenter.default.post(name: .LocationErrorChanged, object: self, userInfo: ["error": locationError])

        if let completion = locationUpdateCompletion {
            completion(.failure(locationError))
            locationUpdateCompletion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        NotificationCenter.default.post(name: .LocationAuthorizationChanged, object: self, userInfo: ["status": status])

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

extension Notification.Name {
    static let LocationUpdated = Notification.Name("LocationUpdated")
    static let LocationAuthorizationChanged = Notification.Name("LocationAuthorizationChanged")
    static let LocationErrorChanged = Notification.Name("LocationErrorChanged")
}

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
