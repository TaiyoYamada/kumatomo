import Foundation

// MARK: - ShopReviewError

enum ShopReviewError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(Int, String)
    case unauthorized
}

// MARK: - ShopReviewAPIService

class ShopReviewAPIService: Sendable {
    static let shared = ShopReviewAPIService()
    private let baseURL = APIConfig.shared.baseURLString

    // Dependencies
    private let session = APISession.shared.session

    private init() {}

    func fetchReviews(placeId: String) async throws -> [Comment] {
        // Endpoint assumption: GET /shops/{place_id}/reviews
        // Since backend might not implement this exactly, we must handle 404.

        let endpoint = "\(baseURL)/shops/\(placeId)/reviews"
        guard let url = URL(string: endpoint) else {
            throw ShopReviewError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = AuthTokenManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ShopReviewError.networkError(NSError(domain: "Invalid Response", code: 0))
            }

            switch httpResponse.statusCode {
            case 200:
                let decoder = APIHelper.makeDecoder()
                return try decoder.decode([Comment].self, from: data)
            case 404:
                return [] // No reviews found or shop not registered yet
            case 401:
                throw ShopReviewError.unauthorized
            default:
                throw ShopReviewError.apiError(httpResponse.statusCode, "Error fetching reviews")
            }
        } catch {
            throw ShopReviewError.networkError(error)
        }
    }
}
