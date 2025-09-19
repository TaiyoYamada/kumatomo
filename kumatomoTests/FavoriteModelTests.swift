import XCTest
@testable import kumatomo

final class FavoriteModelTests: XCTestCase {
    
    func testFavoriteInitialization() {
        // Test basic favorite initialization
        let shop = Shop(id: 1, name: "Test Shop")
        let favorite = Favorite(
            id: 1,
            userId: 100,
            shopId: 1,
            shop: shop
        )
        
        XCTAssertEqual(favorite.id, 1)
        XCTAssertEqual(favorite.userId, 100)
        XCTAssertEqual(favorite.shopId, 1)
        XCTAssertNotNil(favorite.shop)
        XCTAssertEqual(favorite.shop?.id, 1)
        XCTAssertEqual(favorite.shop?.name, "Test Shop")
    }
    
    func testFavoriteDefaultValues() {
        // Test favorite initialization with default values
        let favorite = Favorite(userId: 100, shopId: 1)
        
        XCTAssertEqual(favorite.id, 0)
        XCTAssertEqual(favorite.userId, 100)
        XCTAssertEqual(favorite.shopId, 1)
        XCTAssertNil(favorite.shop)
    }
    
    func testFavoriteCodable() {
        // Test that Favorite can be encoded and decoded
        let shop = Shop(id: 1, name: "Test Shop")
        let originalFavorite = Favorite(
            id: 1,
            userId: 100,
            shopId: 1,
            shop: shop
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(originalFavorite)
            let decodedFavorite = try decoder.decode(Favorite.self, from: data)
            
            XCTAssertEqual(originalFavorite.id, decodedFavorite.id)
            XCTAssertEqual(originalFavorite.userId, decodedFavorite.userId)
            XCTAssertEqual(originalFavorite.shopId, decodedFavorite.shopId)
            XCTAssertEqual(originalFavorite.shop?.id, decodedFavorite.shop?.id)
            XCTAssertEqual(originalFavorite.shop?.name, decodedFavorite.shop?.name)
        } catch {
            XCTFail("Favorite should be codable: \(error)")
        }
    }
    
    func testFavoriteEquatable() {
        // Test that Favorite conforms to Equatable
        let shop = Shop(id: 1, name: "Test Shop")
        
        let favorite1 = Favorite(
            id: 1,
            userId: 100,
            shopId: 1,
            shop: shop
        )
        
        let favorite2 = Favorite(
            id: 1,
            userId: 100,
            shopId: 1,
            shop: shop
        )
        
        let favorite3 = Favorite(
            id: 2,
            userId: 200,
            shopId: 2
        )
        
        XCTAssertEqual(favorite1, favorite2)
        XCTAssertNotEqual(favorite1, favorite3)
    }
}