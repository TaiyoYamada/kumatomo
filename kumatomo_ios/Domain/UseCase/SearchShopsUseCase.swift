import Foundation
import CoreLocation

// MARK: - SearchShopsUseCaseProtocol

protocol SearchShopsUseCaseProtocol: Sendable {
    func execute(query: String?, category: ShopCategory?, location: CLLocationCoordinate2D) async throws -> [Shop]
}

// MARK: - SearchShopsUseCase

final class SearchShopsUseCase: SearchShopsUseCaseProtocol {
    private let inputs: Inputs

    struct Inputs: Sendable {
        let placeRepository: PlaceRepositoryProtocol
    }

    init(inputs: Inputs) {
        self.inputs = inputs
    }

    convenience init(placeRepository: PlaceRepositoryProtocol) {
        self.init(inputs: Inputs(placeRepository: placeRepository))
    }

    func execute(query: String?, category: ShopCategory?, location: CLLocationCoordinate2D) async throws -> [Shop] {
        if let query, !query.isEmpty {
            return try await inputs.placeRepository.searchShops(query: query, location: location)
        } else {
            return try await inputs.placeRepository.fetchNearbyShops(location: location, category: category)
        }
    }
}
