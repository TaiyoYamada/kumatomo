import Combine
import CoreLocation
import Foundation
import Observation

// MARK: - LocationManager

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

        // Start location updates - errors will be handled in didFailWithError delegate
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
        locationError = nil
        NotificationCenter.default.post(
            name: .LocationAuthorizationChanged,
            object: self,
            userInfo: ["status": authorizationStatus]
        )
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

        // Request location - errors will be handled in didFailWithError delegate
        locationManager.requestLocation()
    }

    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    static func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1_000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1_000)
        }
    }

    func distanceFromUser(to coordinate: CLLocationCoordinate2D) -> String? {
        guard let userLocation else { return nil }

        let distance = distance(from: userLocation.coordinate, to: coordinate)
        return LocationManager.formatDistance(distance)
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        authorizationStatus = locationManager.authorizationStatus
    }
}

// MARK: CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }

            let locationAge = -location.timestamp.timeIntervalSinceNow
            guard locationAge < 5.0, location.horizontalAccuracy < 100 else { return }

            userLocation = location
            locationError = nil
            NotificationCenter.default.post(name: .LocationUpdated, object: self, userInfo: ["userLocation": location])

            if let completion = locationUpdateCompletion {
                completion(.success(location))
                locationUpdateCompletion = nil
                manager.stopUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            let locationError: LocationError = if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    .permissionDenied
                case .locationUnknown:
                    .locationUnavailable
                case .network:
                    .networkError
                default:
                    .unknown
                }
            } else {
                .unknown
            }

            self.locationError = locationError
            NotificationCenter.default.post(
                name: .LocationErrorChanged,
                object: self,
                userInfo: ["error": locationError]
            )

            if let completion = locationUpdateCompletion {
                completion(.failure(locationError))
                locationUpdateCompletion = nil
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            authorizationStatus = status
            NotificationCenter.default.post(
                name: .LocationAuthorizationChanged,
                object: self,
                userInfo: ["status": status]
            )

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
}

extension Notification.Name {
    static let LocationUpdated = Notification.Name("LocationUpdated")
    static let LocationAuthorizationChanged = Notification.Name("LocationAuthorizationChanged")
    static let LocationErrorChanged = Notification.Name("LocationErrorChanged")
}
