import Foundation

// Data adapter wrapping SearchAPIService
final class SearchRepositoryImpl: SearchRepository {
    private let service: SearchAPIService

    init(service: SearchAPIService = .shared) {
        self.service = service
    }

    func search(query: String, type: SearchFilterType, page: Int, perPage: Int) async throws -> (SearchResult, Int, Int) {
        let (result, _, _) = try await service.search(query: query, type: type, page: page, perPage: perPage)
        // Pagination values are not provided by service; return requested values
        return (result, page, perPage)
    }
}
