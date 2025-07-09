import Foundation

enum StoryAPIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(Int, String)
    case unknownError(Error)
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
        case .apiError(let code, let message):
            return "APIエラー（コード: \(code)）: \(message)"
        case .unknownError(let error):
            return "不明なエラー: \(error.localizedDescription)"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        case .timeout:
            return "リクエストがタイムアウトしました"
        }
    }
}
