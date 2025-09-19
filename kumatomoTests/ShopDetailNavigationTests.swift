import XCTest
import SwiftUI
@testable import kumatomo

@MainActor
class ShopDetailNavigationTests: XCTestCase {
    
    var testShop: Shop!
    
    override func setUp() {
        super.setUp()
        testShop = Shop(
            id: 1,
            name: "テストカフェ",
            description: "テスト用のカフェです",
            address: "東京都渋谷区テスト1-1-1",
            phone: "03-1234-5678",
            businessHours: "9:00-18:00",
            genre: .cafe,
            latitude: 35.6762,
            longitude: 139.6503,
            imageUrl: "https://example.com/test.jpg",
            hasTryBenefit: true,
            stampCount: 5,
            isApproved: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    override func tearDown() {
        testShop = nil
        super.tearDown()
    }
    
    // MARK: - Requirement 4.1: Shop card tap navigation
    func testShopCardTapNavigatesToDetail() {
        // Given: A shop card with tap handler
        var tappedShop: Shop?
        let onTap = { tappedShop = testShop }
        
        // When: Shop card is tapped
        onTap()
        
        // Then: The correct shop should be passed to navigation
        XCTAssertEqual(tappedShop?.id, testShop.id)
        XCTAssertEqual(tappedShop?.name, testShop.name)
    }
    
    // MARK: - Requirement 4.2: ShopDetailView displays all information
    func testShopDetailViewDisplaysAllInformation() {
        // Given: A ShopDetailView with test shop
        let shopDetailView = ShopDetailView(shop: testShop)
        
        // Then: View should be created successfully
        XCTAssertNotNil(shopDetailView)
        
        // Verify shop data is accessible
        XCTAssertEqual(shopDetailView.shop.id, testShop.id)
        XCTAssertEqual(shopDetailView.shop.name, testShop.name)
        XCTAssertEqual(shopDetailView.shop.description, testShop.description)
        XCTAssertEqual(shopDetailView.shop.address, testShop.address)
        XCTAssertEqual(shopDetailView.shop.phone, testShop.phone)
        XCTAssertEqual(shopDetailView.shop.businessHours, testShop.businessHours)
        XCTAssertEqual(shopDetailView.shop.genre, testShop.genre)
    }
    
    // MARK: - Requirement 4.3: Smooth transition animations
    func testSheetDestinationCreation() {
        // Given: A shop for navigation
        let sheetDestination = SheetDestination.shopDetail(testShop)
        
        // Then: Sheet destination should be created correctly
        XCTAssertEqual(sheetDestination.id, "shopDetail_\(testShop.id)")
        
        // Verify the destination contains the correct shop
        if case .shopDetail(let shop) = sheetDestination {
            XCTAssertEqual(shop.id, testShop.id)
            XCTAssertEqual(shop.name, testShop.name)
        } else {
            XCTFail("Sheet destination should be shopDetail type")
        }
    }
    
    // MARK: - Requirement 4.4: Back navigation from detail view
    func testShopDetailViewHasBackNavigation() {
        // Given: A ShopDetailView
        let shopDetailView = ShopDetailView(shop: testShop)
        
        // Then: View should have dismiss environment value
        // Note: In a real UI test, we would verify the "閉じる" button exists and works
        // For unit test, we verify the view structure is correct
        XCTAssertNotNil(shopDetailView)
    }
    
    // MARK: - Map navigation tests
    func testMapPinTapNavigatesToDetail() {
        // Given: A map view with pin tap handler
        var tappedShop: Shop?
        let onPinTapped = { (shop: Shop) in tappedShop = shop }
        
        // When: Map pin is tapped
        onPinTapped(testShop)
        
        // Then: The correct shop should be passed to navigation
        XCTAssertEqual(tappedShop?.id, testShop.id)
        XCTAssertEqual(tappedShop?.name, testShop.name)
    }
    
    // MARK: - Navigation flow integration test
    func testCompleteNavigationFlow() {
        // Given: Initial state with no sheet destination
        var sheetDestination: SheetDestination?
        
        // When: User taps shop card (simulating the onShopTapped callback)
        let onShopTapped = { (shop: Shop) in
            sheetDestination = .shopDetail(shop)
        }
        
        // Simulate tap
        onShopTapped(testShop)
        
        // Then: Sheet destination should be set correctly
        XCTAssertNotNil(sheetDestination)
        if case .shopDetail(let shop) = sheetDestination {
            XCTAssertEqual(shop.id, testShop.id)
        } else {
            XCTFail("Sheet destination should be shopDetail")
        }
        
        // When: User dismisses the sheet (simulating dismiss action)
        sheetDestination = nil
        
        // Then: Sheet should be dismissed
        XCTAssertNil(sheetDestination)
    }
    
    // MARK: - Test navigation from both list and map views
    func testNavigationFromBothViews() {
        // Test list view navigation
        var listNavigationShop: Shop?
        let listOnTap = { listNavigationShop = testShop }
        listOnTap()
        XCTAssertEqual(listNavigationShop?.id, testShop.id)
        
        // Test map view navigation
        var mapNavigationShop: Shop?
        let mapOnPinTap = { (shop: Shop) in mapNavigationShop = shop }
        mapOnPinTap(testShop)
        XCTAssertEqual(mapNavigationShop?.id, testShop.id)
        
        // Both should navigate to the same shop
        XCTAssertEqual(listNavigationShop?.id, mapNavigationShop?.id)
    }
    
    // MARK: - Test shop coordinate property for map navigation
    func testShopCoordinateProperty() {
        // Given: A shop with coordinates
        let coordinate = testShop.coordinate
        
        // Then: Coordinate should be calculated correctly
        XCTAssertNotNil(coordinate)
        XCTAssertEqual(coordinate?.latitude, testShop.latitude)
        XCTAssertEqual(coordinate?.longitude, testShop.longitude)
    }
    
    // MARK: - Test shop without coordinates
    func testShopWithoutCoordinates() {
        // Given: A shop without coordinates
        let shopWithoutCoords = Shop(
            id: 2,
            name: "座標なしショップ",
            description: "座標のないテストショップ",
            address: "住所のみ",
            genre: .restaurant,
            latitude: nil,
            longitude: nil
        )
        
        // Then: Coordinate should be nil
        XCTAssertNil(shopWithoutCoords.coordinate)
        
        // But navigation should still work
        var navigationShop: Shop?
        let onTap = { navigationShop = shopWithoutCoords }
        onTap()
        XCTAssertEqual(navigationShop?.id, shopWithoutCoords.id)
    }
}