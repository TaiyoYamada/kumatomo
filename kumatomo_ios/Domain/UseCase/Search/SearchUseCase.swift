import Foundation

protocol SearchUseCase {
    func execute(query: String, type: SearchFilterType, page: Int, perPage: Int) async throws -> (SearchResult, Int, Int)
}

final class SearchUseCaseImpl: SearchUseCase {
    private let repository: SearchRepository

    init(repository: SearchRepository) {
        self.repository = repository
    }

    func execute(query: String, type: SearchFilterType, page: Int, perPage: Int) async throws -> (SearchResult, Int, Int) {
        try await repository.search(query: query, type: type, page: page, perPage: perPage)
    }
}

