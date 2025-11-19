import Foundation

enum ShopAPIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case shopNotFound
    case serverError(String)
    case timeout

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .decodingError(let error):
            return "データの読み込みに失敗しました: \(error.localizedDescription)"
        case .shopNotFound:
            return "お店が見つかりません"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        case .timeout:
            return "リクエストがタイムアウトしました"
        }
    }
}