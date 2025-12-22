import Foundation
import CoreLocation

final class PlaceRepositoryImpl: PlaceRepositoryProtocol, Sendable {
    private let client: GooglePlacesClient

    init(client: GooglePlacesClient = GooglePlacesClient()) {
        self.client = client
    }

    func fetchNearbyShops(location: CLLocationCoordinate2D, category: ShopCategory?) async throws -> [Shop] {
        // If category is nil, fetch "all" supported types or top-level types.
        // Google Places API might error if too many includedTypes.
        // For "Nearby", if no category is selected, we usually want "everything around" or defaults.
        // Let's stick to the key categories.

        // Optimisation: if category is nil, maybe limit to restaurant, cafe, convenience_store etc.
        let defaultTypes = [
            "restaurant",
            "cafe",
            "convenience_store",
            "supermarket",
            "shopping_mall",
            "hospital",
            "school",
            "gym"
        ]
        let targetTypes = category?.googlePlaceTypes ?? defaultTypes

        return try await client.searchNearby(location: location, types: targetTypes)
    }

    func searchShops(query: String, location: CLLocationCoordinate2D) async throws -> [Shop] {
        return try await client.searchText(query: query, location: location)
    }
}
