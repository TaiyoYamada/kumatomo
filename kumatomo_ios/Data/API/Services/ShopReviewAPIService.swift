import Foundation

// MARK: - ShopReviewAPIService

/// APIClient経由のショップレビューAPIサービス
class ShopReviewAPIService: @unchecked Sendable {
    static let shared = ShopReviewAPIService()
    private let client = APIClient.shared

    private init() {}

    func fetchReviews(placeId: String) async throws -> [Comment] {
        do {
            let reviews: [Comment] = try await client.get(ShopReviewEndpoint.fetchReviews(placeId: placeId))
            return reviews
        } catch let apiError as APIError {
            switch apiError {
            case .notFound:
                return [] // No reviews found or shop not registered yet
            case .unauthorized:
                throw ShopReviewError.unauthorized
            case let .apiError(statusCode, message):
                throw ShopReviewError.apiError(statusCode, message)
            case let .networkError(error):
                throw ShopReviewError.networkError(error)
            default:
                throw ShopReviewError.networkError(apiError)
            }
        } catch {
            throw ShopReviewError.networkError(error)
        }
    }
}

// MARK: - ShopReviewEndpoint

private enum ShopReviewEndpoint: APIEndpoint {
    case fetchReviews(placeId: String)

    var path: String {
        switch self {
        case let .fetchReviews(placeId):
            return "/shops/\(placeId)/reviews"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchReviews:
            return .get
        }
    }
}
