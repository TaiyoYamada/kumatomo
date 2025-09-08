import Foundation
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: SearchResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: SearchFilterType = .all
    @Published var showingSearchHistory = false
    
    private let searchService = SearchAPIService.shared
    private let historyManager = SearchHistoryManager.shared
    
    var hasSearchResults: Bool {
        guard let results = searchResults else { return false }
        return !results.posts.isEmpty || !results.shops.isEmpty
    }
    
    var searchHistory: [SearchHistory] {
        historyManager.searchHistory
    }
    
    // 検索を実行
    func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        Task {
            await search(query: query)
        }
    }
    
    // 検索履歴から検索
    func searchFromHistory(_ history: SearchHistory) {
        searchText = history.query
        showingSearchHistory = false
        performSearch()
    }
    
    // フィルターを変更
    func changeFilter(to filter: SearchFilterType) {
        selectedFilter = filter
        if !searchText.isEmpty {
            performSearch()
        }
    }
    
    // 検索をクリア
    func clearSearch() {
        searchText = ""
        searchResults = nil
        errorMessage = nil
        showingSearchHistory = false
    }
    
    // 検索履歴を削除
    func removeSearchHistory(at index: Int) {
        historyManager.removeSearchHistory(at: index)
    }
    
    // 検索履歴をすべてクリア
    func clearSearchHistory() {
        historyManager.clearSearchHistory()
    }
    
    // 実際の検索処理
    private func search(query: String) async {
        isLoading = true
        errorMessage = nil
        showingSearchHistory = false
        
        do {
            let (results, _, _) = try await searchService.search(
                query: query,
                type: selectedFilter,
                page: 1,
                perPage: 20
            )
            
            searchResults = results
            
            // 検索履歴に追加
            historyManager.addSearchHistory(query: query)
            
        } catch {
            errorMessage = error.localizedDescription
            print("🚨 検索エラー: \(error)")
        }
        
        isLoading = false
    }
    
    // 検索テキストの変更を監視
    func onSearchTextChanged() {
        // 検索テキストが空の場合は検索履歴を表示
        if searchText.isEmpty {
            showingSearchHistory = true
            searchResults = nil
        } else {
            showingSearchHistory = false
        }
    }
}
