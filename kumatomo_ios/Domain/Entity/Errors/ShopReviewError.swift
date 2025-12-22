import Foundation

// MARK: - ShopReviewError

enum ShopReviewError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(Int, String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case let .networkError(error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case let .decodingError(error):
            return "データ解析エラー: \(error.localizedDescription)"
        case let .apiError(code, message):
            return "APIエラー(\(code)): \(message)"
        case .unauthorized:
            return "認証エラー: ログインが必要です"
        }
    }
}
