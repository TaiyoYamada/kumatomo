import Foundation
import Mockable

@Mockable
protocol SearchRepository {
    func search(query: String, type: SearchFilterType, page: Int, perPage: Int) async throws -> (SearchResult, Int, Int)
}
