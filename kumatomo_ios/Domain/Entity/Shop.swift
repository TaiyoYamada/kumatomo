import Foundation
import CoreLocation

struct Shop: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let coordinate: Coordinate
    let address: String
    let isOpen: Bool?
    let rating: Double?
    let category: ShopCategory?
    let iconURL: URL?

    struct Coordinate: Hashable, Sendable {
        let latitude: Double
        let longitude: Double

        var clLocationCoordinate2D: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}
