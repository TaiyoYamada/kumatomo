import CoreLocation
import Foundation
import Mockable

@Mockable
protocol PlaceRepositoryProtocol: Sendable {
    func fetchNearbyShops(location: CLLocationCoordinate2D, category: ShopCategory?) async throws -> [Shop]
    func searchShops(query: String, location: CLLocationCoordinate2D) async throws -> [Shop]
}
