import Foundation
import CoreLocation

// MARK: - GooglePlacesClient

final class GooglePlacesClient: Sendable {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = APIConfig.googlePlacesAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    func nearbySearch(location: CLLocationCoordinate2D, type: String?) async throws -> [Shop] {
        guard let components = URLComponents(string: "https://places.googleapis.com/v1/places:searchNearby") else {
            throw PlaceError.networkError(NSError(domain: "Invalid URL", code: 0))
        }

        let includedTypes: [String] = type.map { [$0] } ?? []
        let requestBody: [String: Any] = [
            "includedTypes": includedTypes,
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": location.latitude,
                        "longitude": location.longitude
                    ],
                    "radius": 1_000.0
                ]
            ]
        ]

        // If type is nil or empty, we might want to search generically or use a different endpoint.
        // For v1 searchNearby, includedTypes is required if we don't specify other filters.
        // However, the requirement says "Map + Bottom Sheet", "Search nearby".
        // Let's use generic restaurant/food types if none specified, or handle "all" case.
        // But for now, let's implement the basic structure.

        // Wait, Google Places API New (v1) requires FieldMask.
        // And searchNearby is POST.

        guard let url = components.url else {
            throw PlaceError.networkError(NSError(domain: "Invalid URL", code: 0))
        }
        return try await performRequest(url: url, method: "POST", body: requestBody)
    }

    // Changing strategy: Use "places:searchNearby" for category search and "places:searchText" for text search.
    // Spec says: Nearby Search (initial), Text Search (search/category).
    // Actually, Text Search is better for "category" if we map category to keywords/types efficiently,
    // but Nearby Search is better for "around me".

    // Let's refine the implementation below properly.
}

extension GooglePlacesClient {
    func searchNearby(location: CLLocationCoordinate2D, types: [String]) async throws -> [Shop] {
        guard let url = URL(string: "https://places.googleapis.com/v1/places:searchNearby") else {
            throw PlaceError.networkError(NSError(domain: "Invalid URL", code: 0))
        }

        let requestBody: [String: Any] = [
            "includedTypes": types,
            "maxResultCount": 50,
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": location.latitude,
                        "longitude": location.longitude
                    ],
                    "radius": 1_500.0
                ]
            ]
        ]

        return try await performRequest(url: url, method: "POST", body: requestBody)
    }

    func searchText(query: String, location: CLLocationCoordinate2D) async throws -> [Shop] {
        guard let url = URL(string: "https://places.googleapis.com/v1/places:searchText") else {
            throw PlaceError.networkError(NSError(domain: "Invalid URL", code: 0))
        }

        let requestBody: [String: Any] = [
            "textQuery": query,
            "locationBias": [
                "circle": [
                    "center": [
                        "latitude": location.latitude,
                        "longitude": location.longitude
                    ],
                    "radius": 1_000.0
                ]
            ]
        ]

        return try await performRequest(url: url, method: "POST", body: requestBody)
    }

    private func performRequest(url: URL, method: String, body: [String: Any]) async throws -> [Shop] {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "places.id,places.displayName,places.formattedAddress,places.location,places.businessStatus,places.rating,places.types,places.regularOpeningHours",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlaceError.networkError(NSError(domain: "Invalid Response", code: 0))
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw PlaceError.apiError("Status: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(GooglePlacesResponse.self, from: data)

        return apiResponse.places?.map { $0.toEntity() } ?? []
    }
}

// MARK: - GooglePlacesResponse

private struct GooglePlacesResponse: Decodable {
    let places: [GooglePlaceDTO]?
}

// MARK: - GooglePlaceDTO

private struct GooglePlaceDTO: Decodable {
    let id: String
    let displayName: DisplayNameDTO?
    let formattedAddress: String?
    let location: LocationDTO?
    let businessStatus: String?
    let rating: Double?
    let types: [String]?
    let regularOpeningHours: OpeningHoursDTO?

    func toEntity() -> Shop {
        let mappedCategory = types?.compactMap { typeString -> ShopCategory? in
            for category in ShopCategory.allCases where category.googlePlaceTypes.contains(typeString) {
                return category
            }
            return nil
        }.first ?? .other

        let isOpenNow = regularOpeningHours?.openNow

        return Shop(
            id: id,
            name: displayName?.text ?? "Unknown",
            coordinate: Shop.Coordinate(latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0),
            address: formattedAddress ?? "",
            isOpen: isOpenNow,
            rating: rating,
            category: mappedCategory,
            iconURL: nil
        )
    }
}

// MARK: - DisplayNameDTO

private struct DisplayNameDTO: Decodable {
    let text: String
}

// MARK: - LocationDTO

private struct LocationDTO: Decodable {
    let latitude: Double
    let longitude: Double
}

// MARK: - OpeningHoursDTO

private struct OpeningHoursDTO: Decodable {
    let openNow: Bool?
}
