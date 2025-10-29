import Foundation

// Domain layer protocol for search operations
protocol SearchRepository {
    func search(query: String, type: SearchFilterType, page: Int, perPage: Int) async throws -> (SearchResult, Int, Int)
}
