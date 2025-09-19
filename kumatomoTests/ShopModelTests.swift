import XCTest
import CoreLocation
@testable import kumatomo

final class ShopModelTests: XCTestCase {
    
    func testShopInitialization() {
        // Test basic shop initialization
        let shop = Shop(
            id: 1,
            name: "Test Shop",
            description: "A test shop",
            address: "123 Test Street",
            phone: "123-456-7890",
            businessHours: "9:00-18:00",
            genre: .cafe,
            latitude: 35.6812,
            longitude: 139.7671,
            imageUrl: "https://example.com/image.jpg",
            hasTryBenefit: true,
            stampCount: 5,
            isApproved: true
        )
        
        XCTAssertEqual(shop.id, 1)
        XCTAssertEqual(shop.name, "Test Shop")
        XCTAssertEqual(shop.description, "A test shop")
        XCTAssertEqual(shop.address, "123 Test Street")
        XCTAssertEqual(shop.phone, "123-456-7890")
        XCTAssertEqual(shop.businessHours, "9:00-18:00")
        XCTAssertEqual(shop.genre, .cafe)
        XCTAssertEqual(shop.latitude, 35.6812)
        XCTAssertEqual(shop.longitude, 139.7671)
        XCTAssertEqual(shop.imageUrl, "https://example.com/image.jpg")
        XCTAssertEqual(shop.hasTryBenefit, true)
        XCTAssertEqual(shop.stampCount, 5)
        XCTAssertEqual(shop.isApproved, true)
    }
    
    func testShopDefaultValues() {
        // Test shop initialization with default values
        let shop = Shop(name: "Minimal Shop")
        
        XCTAssertEqual(shop.id, 0)
        XCTAssertEqual(shop.name, "Minimal Shop")
        XCTAssertNil(shop.description)
        XCTAssertNil(shop.address)
        XCTAssertNil(shop.phone)
        XCTAssertNil(shop.businessHours)
        XCTAssertNil(shop.genre)
        XCTAssertNil(shop.latitude)
        XCTAssertNil(shop.longitude)
        XCTAssertNil(shop.imageUrl)
        XCTAssertEqual(shop.hasTryBenefit, false)
        XCTAssertEqual(shop.stampCount, 0)
        XCTAssertEqual(shop.isApproved, true)
    }
    
    func testShopCoordinate() {
        // Test coordinate computation
        let shopWithCoordinates = Shop(
            name: "Located Shop",
            latitude: 35.6812,
            longitude: 139.7671
        )
        
        let coordinate = shopWithCoordinates.coordinate
        XCTAssertNotNil(coordinate)
        XCTAssertEqual(coordinate?.latitude, 35.6812, accuracy: 0.0001)
        XCTAssertEqual(coordinate?.longitude, 139.7671, accuracy: 0.0001)
        
        // Test shop without coordinates
        let shopWithoutCoordinates = Shop(name: "No Location Shop")
        XCTAssertNil(shopWithoutCoordinates.coordinate)
    }
    
    func testDistanceCalculation() {
        // Test distance calculation
        let shop = Shop(
            name: "Distance Test Shop",
            latitude: 35.6812,
            longitude: 139.7671
        )
        
        // User location close to shop (about 100m away)
        let userLocation = CLLocation(latitude: 35.6822, longitude: 139.7671)
        let distance = shop.distanceFromUser(userLocation)
        
        XCTAssertNotNil(distance)
        XCTAssertTrue(distance!.hasSuffix("m"), "Distance should be in meters for short distances")
        
        // User location far from shop (about 10km away)
        let farUserLocation = CLLocation(latitude: 35.7812, longitude: 139.7671)
        let farDistance = shop.distanceFromUser(farUserLocation)
        
        XCTAssertNotNil(farDistance)
        XCTAssertTrue(farDistance!.hasSuffix("km"), "Distance should be in kilometers for long distances")
        
        // Test with no user location
        let noDistance = shop.distanceFromUser(nil)
        XCTAssertNil(noDistance)
        
        // Test shop without coordinates
        let shopNoCoords = Shop(name: "No Coords Shop")
        let noDistanceNoCoords = shopNoCoords.distanceFromUser(userLocation)
        XCTAssertNil(noDistanceNoCoords)
    }
    
    func testShopCodable() {
        // Test that Shop can be encoded and decoded
        let originalShop = Shop(
            id: 1,
            name: "Codable Shop",
            description: "Test description",
            address: "Test address",
            phone: "123-456-7890",
            businessHours: "9:00-18:00",
            genre: .ramen,
            latitude: 35.6812,
            longitude: 139.7671,
            imageUrl: "https://example.com/image.jpg",
            hasTryBenefit: true,
            stampCount: 3,
            isApproved: true
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(originalShop)
            let decodedShop = try decoder.decode(Shop.self, from: data)
            
            XCTAssertEqual(originalShop.id, decodedShop.id)
            XCTAssertEqual(originalShop.name, decodedShop.name)
            XCTAssertEqual(originalShop.description, decodedShop.description)
            XCTAssertEqual(originalShop.address, decodedShop.address)
            XCTAssertEqual(originalShop.phone, decodedShop.phone)
            XCTAssertEqual(originalShop.businessHours, decodedShop.businessHours)
            XCTAssertEqual(originalShop.genre, decodedShop.genre)
            XCTAssertEqual(originalShop.latitude, decodedShop.latitude)
            XCTAssertEqual(originalShop.longitude, decodedShop.longitude)
            XCTAssertEqual(originalShop.imageUrl, decodedShop.imageUrl)
            XCTAssertEqual(originalShop.hasTryBenefit, decodedShop.hasTryBenefit)
            XCTAssertEqual(originalShop.stampCount, decodedShop.stampCount)
            XCTAssertEqual(originalShop.isApproved, decodedShop.isApproved)
        } catch {
            XCTFail("Shop should be codable: \(error)")
        }
    }
    
    func testShopEquatable() {
        // Test that Shop conforms to Equatable
        let shop1 = Shop(
            id: 1,
            name: "Test Shop",
            hasTryBenefit: true,
            stampCount: 5
        )
        
        let shop2 = Shop(
            id: 1,
            name: "Test Shop",
            hasTryBenefit: true,
            stampCount: 5
        )
        
        let shop3 = Shop(
            id: 2,
            name: "Different Shop",
            hasTryBenefit: false,
            stampCount: 0
        )
        
        XCTAssertEqual(shop1, shop2)
        XCTAssertNotEqual(shop1, shop3)
    }
}