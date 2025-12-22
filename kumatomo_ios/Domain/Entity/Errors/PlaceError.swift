import Foundation

// MARK: - PlaceError

enum PlaceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case let .networkError(error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case let .decodingError(error):
            return "データ解析エラー: \(error.localizedDescription)"
        case let .apiError(message):
            return "APIエラー: \(message)"
        }
    }
}
