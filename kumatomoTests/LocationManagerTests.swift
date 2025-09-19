import XCTest
import CoreLocation
@testable import kumatomo

class LocationManagerTests: XCTestCase {
    
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager = nil
        super.tearDown()
    }
    
    // MARK: - Distance Calculation Tests
    
    func testDistanceCalculationBetweenCoordinates() {
        // Given: Two coordinates in Tokyo (approximately 1km apart)
        let coordinate1 = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503) // Shibuya
        let coordinate2 = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.6671) // Shinjuku
        
        // When: Calculating distance
        let distance = locationManager.distance(from: coordinate1, to: coordinate2)
        
        // Then: Distance should be approximately 1.5km (1500m)
        XCTAssertGreaterThan(distance, 1000, "Distance should be greater than 1km")
        XCTAssertLessThan(distance, 2000, "Distance should be less than 2km")
    }
    
    func testDistanceCalculationSameLocation() {
        // Given: Same coordinates
        let coordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        
        // When: Calculating distance
        let distance = locationManager.distance(from: coordinate, to: coordinate)
        
        // Then: Distance should be 0
        XCTAssertEqual(distance, 0, accuracy: 0.1, "Distance to same location should be 0")
    }
    
    // MARK: - Distance Formatting Tests
    
    func testFormatDistanceInMeters() {
        // Given: Distance less than 1000m
        let distance: CLLocationDistance = 250.7
        
        // When: Formatting distance
        let formattedDistance = locationManager.formatDistance(distance)
        
        // Then: Should be formatted in meters without decimal
        XCTAssertEqual(formattedDistance, "251m", "Distance should be formatted as meters")
    }
    
    func testFormatDistanceInKilometers() {
        // Given: Distance greater than 1000m
        let distance: CLLocationDistance = 1500.8
        
        // When: Formatting distance
        let formattedDistance = locationManager.formatDistance(distance)
        
        // Then: Should be formatted in kilometers with one decimal
        XCTAssertEqual(formattedDistance, "1.5km", "Distance should be formatted as kilometers")
    }
    
    func testFormatDistanceExactlyOneKilometer() {
        // Given: Distance exactly 1000m
        let distance: CLLocationDistance = 1000.0
        
        // When: Formatting distance
        let formattedDistance = locationManager.formatDistance(distance)
        
        // Then: Should be formatted as 1.0km
        XCTAssertEqual(formattedDistance, "1.0km", "Distance should be formatted as 1.0km")
    }
    
    func testFormatDistanceVerySmall() {
        // Given: Very small distance
        let distance: CLLocationDistance = 5.2
        
        // When: Formatting distance
        let formattedDistance = locationManager.formatDistance(distance)
        
        // Then: Should be formatted as 5m
        XCTAssertEqual(formattedDistance, "5m", "Small distance should be formatted as meters")
    }
    
    func testFormatDistanceLarge() {
        // Given: Large distance
        let distance: CLLocationDistance = 15750.3
        
        // When: Formatting distance
        let formattedDistance = locationManager.formatDistance(distance)
        
        // Then: Should be formatted as 15.8km
        XCTAssertEqual(formattedDistance, "15.8km", "Large distance should be formatted as kilometers")
    }
    
    // MARK: - Distance from User Tests
    
    func testDistanceFromUserWithoutUserLocation() {
        // Given: No user location set
        locationManager.userLocation = nil
        let coordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        
        // When: Calculating distance from user
        let distance = locationManager.distanceFromUser(to: coordinate)
        
        // Then: Should return nil
        XCTAssertNil(distance, "Distance should be nil when user location is not available")
    }
    
    func testDistanceFromUserWithUserLocation() {
        // Given: User location is set
        let userLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
        locationManager.userLocation = userLocation
        
        let shopCoordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.6671)
        
        // When: Calculating distance from user
        let distance = locationManager.distanceFromUser(to: shopCoordinate)
        
        // Then: Should return formatted distance
        XCTAssertNotNil(distance, "Distance should not be nil when user location is available")
        XCTAssertTrue(distance!.hasSuffix("km") || distance!.hasSuffix("m"), "Distance should have proper unit")
    }
    
    func testDistanceFromUserToShopWithoutCoordinates() {
        // Given: User location is set but shop has no coordinates
        let userLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
        locationManager.userLocation = userLocation
        
        let shop = Shop(name: "Test Shop") // No coordinates
        
        // When: Calculating distance from user to shop
        let distance = locationManager.distanceFromUser(to: shop)
        
        // Then: Should return nil
        XCTAssertNil(distance, "Distance should be nil when shop has no coordinates")
    }
    
    func testDistanceFromUserToShopWithCoordinates() {
        // Given: User location and shop with coordinates
        let userLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
        locationManager.userLocation = userLocation
        
        let shop = Shop(
            name: "Test Shop",
            latitude: 35.6812,
            longitude: 139.6671
        )
        
        // When: Calculating distance from user to shop
        let distance = locationManager.distanceFromUser(to: shop)
        
        // Then: Should return formatted distance
        XCTAssertNotNil(distance, "Distance should not be nil when both locations are available")
        XCTAssertTrue(distance!.hasSuffix("km") || distance!.hasSuffix("m"), "Distance should have proper unit")
    }
    
    // MARK: - Authorization Status Tests
    
    func testInitialAuthorizationStatus() {
        // Given: Fresh LocationManager instance
        let newLocationManager = LocationManager()
        
        // When: Checking initial authorization status
        let status = newLocationManager.authorizationStatus
        
        // Then: Should have a valid status
        XCTAssertTrue([
            .notDetermined,
            .denied,
            .restricted,
            .authorizedWhenInUse,
            .authorizedAlways
        ].contains(status), "Authorization status should be a valid CLAuthorizationStatus")
    }
    
    // MARK: - Location Error Tests
    
    func testLocationErrorDescriptions() {
        // Test all location error descriptions
        let errors: [LocationError] = [
            .permissionDenied,
            .locationServicesDisabled,
            .locationUnavailable,
            .networkError,
            .unknown
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error description should not be nil for \(error)")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty for \(error)")
        }
    }
    
    func testLocationErrorLocalizedDescriptions() {
        // Test specific error messages
        XCTAssertTrue(LocationError.permissionDenied.errorDescription!.contains("許可"), 
                     "Permission denied error should mention permission in Japanese")
        XCTAssertTrue(LocationError.locationServicesDisabled.errorDescription!.contains("位置情報サービス"), 
                     "Location services disabled error should mention location services in Japanese")
        XCTAssertTrue(LocationError.locationUnavailable.errorDescription!.contains("取得できませんでした"), 
                     "Location unavailable error should mention inability to obtain location in Japanese")
        XCTAssertTrue(LocationError.networkError.errorDescription!.contains("ネットワーク"), 
                     "Network error should mention network in Japanese")
        XCTAssertTrue(LocationError.unknown.errorDescription!.contains("予期しない"), 
                     "Unknown error should mention unexpected error in Japanese")
    }
    
    // MARK: - Performance Tests
    
    func testDistanceCalculationPerformance() {
        // Given: Multiple coordinates for performance testing
        let coordinates = (0..<1000).map { i in
            CLLocationCoordinate2D(
                latitude: 35.6762 + Double(i) * 0.001,
                longitude: 139.6503 + Double(i) * 0.001
            )
        }
        
        let baseCoordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        
        // When: Measuring distance calculation performance
        measure {
            for coordinate in coordinates {
                _ = locationManager.distance(from: baseCoordinate, to: coordinate)
            }
        }
    }
    
    func testDistanceFormattingPerformance() {
        // Given: Multiple distances for performance testing
        let distances = (0..<1000).map { i in
            CLLocationDistance(i * 10)
        }
        
        // When: Measuring distance formatting performance
        measure {
            for distance in distances {
                _ = locationManager.formatDistance(distance)
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testDistanceCalculationWithInvalidCoordinates() {
        // Given: Invalid coordinates
        let invalidCoordinate1 = CLLocationCoordinate2D(latitude: 91.0, longitude: 181.0) // Out of range
        let validCoordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        
        // When: Calculating distance with invalid coordinates
        let distance = locationManager.distance(from: invalidCoordinate1, to: validCoordinate)
        
        // Then: Should still return a distance (CoreLocation handles invalid coordinates)
        XCTAssertGreaterThanOrEqual(distance, 0, "Distance should be non-negative even with invalid coordinates")
    }
    
    func testDistanceFormattingWithZero() {
        // Given: Zero distance
        let distance: CLLocationDistance = 0.0
        
        // When: Formatting zero distance
        let formattedDistance = locationManager.formatDistance(distance)
        
        // Then: Should be formatted as 0m
        XCTAssertEqual(formattedDistance, "0m", "Zero distance should be formatted as 0m")
    }
    
    func testDistanceFormattingWithNegativeValue() {
        // Given: Negative distance (edge case)
        let distance: CLLocationDistance = -100.0
        
        // When: Formatting negative distance
        let formattedDistance = locationManager.formatDistance(distance)
        
        // Then: Should handle negative values gracefully
        XCTAssertTrue(formattedDistance.contains("-") || formattedDistance == "0m", 
                     "Negative distance should be handled gracefully")
    }
}