import CoreLocation
import Factory
import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - ShopViewModelTests

/// ショップViewModelのテスト
@Suite("ShopViewModel Tests")
@MainActor
struct ShopViewModelTests {
    @Test("初期状態で空のショップリスト")
    func initialStateShouldHaveEmptyShops() async {
        // Given
        let sut = ShopViewModel()

        // Then
        #expect(sut.shops.isEmpty)
        #expect(sut.selectedShop == nil)
        #expect(sut.searchQuery == "")
        #expect(sut.selectedCategory == nil)
    }

    @Test("検索クエリ変更でリセットされる")
    func onSearchQueryChangedShouldResetShops() async {
        // Given
        let sut = ShopViewModel()

        // When
        sut.onSearchQueryChanged("ラーメン")

        // Then
        #expect(sut.searchQuery == "ラーメン")
        #expect(sut.shops.isEmpty) // リセットされる
    }

    @Test("カテゴリ選択が正常動作")
    func onCategorySelectedShouldToggle() async {
        // Given
        let sut = ShopViewModel()
        let category = ShopCategory.restaurant

        // When - select
        sut.onCategorySelected(category)

        // Then
        #expect(sut.selectedCategory == category)

        // When - toggle off
        sut.onCategorySelected(category)

        // Then
        #expect(sut.selectedCategory == nil)
    }

    @Test("マップタップでボトムシートが閉じる")
    func onMapTappedShouldHideBottomSheet() async {
        // Given
        let sut = ShopViewModel()
        sut.bottomSheetState = .collapsed
        sut.selectedShop = Shop(
            id: "1",
            name: "テストショップ",
            coordinate: Shop.Coordinate(latitude: 32.8, longitude: 130.7),
            address: "熊本県",
            isOpen: true,
            rating: 4.5,
            category: .restaurant,
            iconURL: nil,
            openingHours: nil
        )

        // When
        sut.onMapTapped()

        // Then
        #expect(sut.bottomSheetState == .hidden)
        #expect(sut.selectedShop == nil)
    }

    @Test("isSearchingは初期false")
    func isSearchingShouldBeFalseInitially() async {
        // Given
        let sut = ShopViewModel()

        // Then
        #expect(sut.isSearching == false)
    }
}
