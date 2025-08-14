import Foundation

class SearchHistoryManager: ObservableObject {
    static let shared = SearchHistoryManager()
    
    @Published var searchHistory: [SearchHistory] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "search_history"
    private let maxHistoryCount = 20
    
    private init() {
        loadSearchHistory()
    }
    
    // 検索履歴を保存
    func addSearchHistory(query: String) {
        // 空のクエリは保存しない
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 既存の同じクエリを削除
        searchHistory.removeAll { $0.query == query }
        
        // 新しい履歴を先頭に追加
        let newHistory = SearchHistory(query: query, timestamp: Date())
        searchHistory.insert(newHistory, at: 0)
        
        // 最大件数を超えた場合は古いものを削除
        if searchHistory.count > maxHistoryCount {
            searchHistory = Array(searchHistory.prefix(maxHistoryCount))
        }
        
        saveSearchHistory()
    }
    
    // 特定の検索履歴を削除
    func removeSearchHistory(at index: Int) {
        guard index < searchHistory.count else { return }
        searchHistory.remove(at: index)
        saveSearchHistory()
    }
    
    // 検索履歴をすべてクリア
    func clearSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }
    
    // 検索履歴をUserDefaultsから読み込み
    private func loadSearchHistory() {
        guard let data = userDefaults.data(forKey: historyKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            searchHistory = try decoder.decode([SearchHistory].self, from: data)
        } catch {
            print("🚨 検索履歴の読み込みに失敗: \(error)")
            searchHistory = []
        }
    }
    
    // 検索履歴をUserDefaultsに保存
    private func saveSearchHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(searchHistory)
            userDefaults.set(data, forKey: historyKey)
        } catch {
            print("🚨 検索履歴の保存に失敗: \(error)")
        }
    }
}