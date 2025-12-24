import Factory
import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - SearchViewModelTests

/// 検索ViewModelのテスト
@Suite("SearchViewModel Tests")
@MainActor
struct SearchViewModelTests {
    @Test("空の検索テキストでは検索を実行しない")
    func performSearchShouldNotSearchWithEmptyText() async {
        // Given
        let sut = SearchViewModel()
        sut.searchText = ""

        // When
        sut.performSearch()

        // Then
        #expect(sut.searchResults == nil)
        #expect(sut.isLoading == false)
    }

    @Test("検索クリアでリセットされる")
    func clearSearchShouldResetState() async {
        // Given
        let sut = SearchViewModel()
        sut.searchText = "テスト"
        let pagination = SearchPagination(currentPage: 1, perPage: 20, posts: nil)
        sut.searchResults = SearchResult(posts: PostFixtures.samplePosts, pagination: pagination)
        sut.errorMessage = "エラー"

        // When
        sut.clearSearch()

        // Then
        #expect(sut.searchText == "")
        #expect(sut.searchResults == nil)
        #expect(sut.errorMessage == nil)
        #expect(sut.showingSearchHistory == false)
    }

    @Test("フィルター変更が正しく反映される")
    func changeFilterShouldUpdateSelectedFilter() async {
        // Given
        let sut = SearchViewModel()

        // When
        sut.changeFilter(to: .posts)

        // Then
        #expect(sut.selectedFilter == .posts)
    }

    @Test("検索テキスト変更時に履歴表示が切り替わる")
    func onSearchTextChangedShouldToggleHistoryVisibility() async {
        // Given
        let sut = SearchViewModel()

        // When empty
        sut.searchText = ""
        sut.onSearchTextChanged()

        // Then
        #expect(sut.showingSearchHistory == true)
        #expect(sut.searchResults == nil)

        // When has text
        sut.searchText = "熊本"
        sut.onSearchTextChanged()

        // Then
        #expect(sut.showingSearchHistory == false)
    }

    @Test("検索結果がない場合hasSearchResultsはfalse")
    func hasSearchResultsShouldBeFalseWhenEmpty() async {
        // Given
        let sut = SearchViewModel()
        sut.searchResults = nil

        // Then
        #expect(sut.hasSearchResults == false)
    }

    @Test("検索結果がある場合hasSearchResultsはtrue")
    func hasSearchResultsShouldBeTrueWithResults() async {
        // Given
        let sut = SearchViewModel()
        let pagination = SearchPagination(currentPage: 1, perPage: 20, posts: nil)
        sut.searchResults = SearchResult(posts: PostFixtures.samplePosts, pagination: pagination)

        // Then
        #expect(sut.hasSearchResults == true)
    }
}
