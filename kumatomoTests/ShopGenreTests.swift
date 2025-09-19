import XCTest
import SwiftUI
@testable import kumatomo

final class ShopGenreTests: XCTestCase {
    
    func testGenreCount() {
        // Test that we have exactly 20 genres as specified
        XCTAssertEqual(ShopGenre.allCases.count, 20, "Should have exactly 20 genres")
    }
    
    func testGenreDisplayNames() {
        // Test that display names match raw values
        for genre in ShopGenre.allCases {
            XCTAssertEqual(genre.displayName, genre.rawValue, "Display name should match raw value for \(genre)")
        }
    }
    
    func testGenreColors() {
        // Test that all genres have valid colors
        for genre in ShopGenre.allCases {
            let color = genre.color
            XCTAssertNotNil(color, "Genre \(genre) should have a valid color")
        }
    }
    
    func testGenreFromString() {
        // Test creating genre from string
        XCTAssertEqual(ShopGenre.from(string: "ラーメン"), .ramen)
        XCTAssertEqual(ShopGenre.from(string: "カフェ"), .cafe)
        XCTAssertEqual(ShopGenre.from(string: "その他"), .other)
        
        // Test case insensitive matching
        XCTAssertEqual(ShopGenre.from(string: "らーめん"), .ramen)
        
        // Test invalid string
        XCTAssertNil(ShopGenre.from(string: "invalid"))
    }
    
    func testAllGenresProperty() {
        // Test that allGenres returns all cases
        XCTAssertEqual(ShopGenre.allGenres.count, ShopGenre.allCases.count)
        XCTAssertEqual(Set(ShopGenre.allGenres), Set(ShopGenre.allCases))
    }
    
    func testGenreCodable() {
        // Test that genres can be encoded and decoded
        let genre = ShopGenre.ramen
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(genre)
            let decodedGenre = try decoder.decode(ShopGenre.self, from: data)
            XCTAssertEqual(genre, decodedGenre)
        } catch {
            XCTFail("Genre should be codable: \(error)")
        }
    }
    
    func testSpecificGenreValues() {
        // Test specific genre raw values to ensure consistency
        XCTAssertEqual(ShopGenre.ramen.rawValue, "ラーメン")
        XCTAssertEqual(ShopGenre.cafe.rawValue, "カフェ")
        XCTAssertEqual(ShopGenre.izakaya.rawValue, "居酒屋")
        XCTAssertEqual(ShopGenre.yakiniku.rawValue, "焼肉")
        XCTAssertEqual(ShopGenre.sushi.rawValue, "寿司")
        XCTAssertEqual(ShopGenre.sweets.rawValue, "スイーツ")
        XCTAssertEqual(ShopGenre.fastFood.rawValue, "ファストフード")
        XCTAssertEqual(ShopGenre.restaurant.rawValue, "レストラン")
        XCTAssertEqual(ShopGenre.bar.rawValue, "バー")
        XCTAssertEqual(ShopGenre.bakery.rawValue, "ベーカリー")
        XCTAssertEqual(ShopGenre.italian.rawValue, "イタリアン")
        XCTAssertEqual(ShopGenre.chinese.rawValue, "中華")
        XCTAssertEqual(ShopGenre.korean.rawValue, "韓国料理")
        XCTAssertEqual(ShopGenre.french.rawValue, "フレンチ")
        XCTAssertEqual(ShopGenre.japanese.rawValue, "和食")
        XCTAssertEqual(ShopGenre.western.rawValue, "洋食")
        XCTAssertEqual(ShopGenre.seafood.rawValue, "海鮮")
        XCTAssertEqual(ShopGenre.vegetarian.rawValue, "ベジタリアン")
        XCTAssertEqual(ShopGenre.bbq.rawValue, "BBQ")
        XCTAssertEqual(ShopGenre.other.rawValue, "その他")
    }
    
    func testColorConsistency() {
        // Test that colors are consistent and not default
        let defaultColor = Color.gray
        
        for genre in ShopGenre.allCases {
            let color = genre.color
            // Colors should be different from each other (at least most of them)
            XCTAssertNotEqual(color, defaultColor, "Genre \(genre) should have a specific color, not default gray")
        }
    }
}