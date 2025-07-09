import Foundation

enum ImageUploadError: Error {
    case imageConversionFailed
    case uploadFailed(reason: String)
    case decodingFailed(error: Error)
    case invalidURL
    
    var localizedDescription: String {
        switch self {
        case .imageConversionFailed:
            return "画像の変換に失敗しました"
        case .uploadFailed(let reason):
            return "画像アップロードに失敗しました: \(reason)"
        case .decodingFailed(let error):
            return "画像アップロードレスポンスのデコードに失敗しました: \(error.localizedDescription)"
        case .invalidURL:
            return "無効なURLです"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .imageConversionFailed:
            return "画像をJPEG形式に変換できませんでした"
        case .uploadFailed(let reason):
            return reason
        case .decodingFailed:
            return "サーバーからのレスポンスが期待した形式ではありません"
        case .invalidURL:
            return "APIのURLが正しく設定されていません"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .imageConversionFailed:
            return "別の画像を選択するか、画像の形式を確認してください"
        case .uploadFailed:
            return "ネットワーク接続を確認し、再度お試しください"
        case .decodingFailed:
            return "アプリを再起動するか、管理者に連絡してください"
        case .invalidURL:
            return "アプリの設定を確認するか、管理者に連絡してください"
        }
    }
}