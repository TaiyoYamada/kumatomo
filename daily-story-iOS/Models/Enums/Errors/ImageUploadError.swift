import Foundation
import UIKit

enum ImageUploadError: LocalizedError {
    case invalidImageData
    case imageCompressionFailed
    case imageConversionFailed
    case fileSizeExceeded(currentSize: Int, maxSize: Int)
    case unsupportedImageFormat
    case decodingFailed(Error)
    case uploadFailed(reason: String)
    case networkError(Error)
    case serverError(statusCode: Int, message: String)
    case timeout
    case insufficientStorage
    case imageTooLarge(width: Int, height: Int, maxWidth: Int, maxHeight: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "画像データが無効です"
        case .imageCompressionFailed:
            return "画像の圧縮に失敗しました"
        case .fileSizeExceeded(let currentSize, let maxSize):
            return "ファイルサイズが上限を超えています (\(formatFileSize(currentSize))/\(formatFileSize(maxSize)))"
        case .imageConversionFailed:
            return "画像の変換に失敗しました"
        case .unsupportedImageFormat:
            return "対応していない画像形式です"
        case .decodingFailed(let error):
            return "レスポンスの解析に失敗しました"
        case .uploadFailed(let reason):
            return "画像のアップロードに失敗しました: \(reason)"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "サーバーエラー (コード: \(statusCode)): \(message)"
        case .timeout:
            return "アップロードがタイムアウトしました"
        case .insufficientStorage:
            return "サーバーの容量が不足しています"
        case .imageTooLarge(let width, let height, let maxWidth, let maxHeight):
            return "画像サイズが大きすぎます (\(width)x\(height)px, 最大: \(maxWidth)x\(maxHeight)px)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidImageData:
            return "別の画像を選択してください"
        case .imageCompressionFailed:
            return "画像のサイズを小さくしてから再試行してください"
        case .imageConversionFailed:
            return "JPEG、PNG、HEIFなどの対応形式の画像を選択してください"
        case .fileSizeExceeded:
            return "画像を圧縮するか、より小さなファイルを選択してください"
        case .unsupportedImageFormat:
            return "JPEG、PNG、HEIFなどの対応形式の画像を選択してください"
        case .decodingFailed:
            return "アプリを最新バージョンにアップデートしてみてください"
        case .uploadFailed:
            return "しばらく時間をおいてから再試行してください"
        case .networkError:
            return "ネットワーク接続を確認してから再試行してください"
        case .serverError:
            return "しばらく時間をおいてから再試行してください"
        case .timeout:
            return "通信環境を確認して再試行してください"
        case .insufficientStorage:
            return "管理者に連絡してください"
        case .imageTooLarge:
            return "画像のサイズを小さくしてから再試行してください"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidImageData:
            return "選択された画像データが読み込めません"
        case .imageCompressionFailed:
            return "画像の圧縮処理でエラーが発生しました"
        case .imageConversionFailed:
            return "画像の形式変換処理でエラーが発生しました"
        case .fileSizeExceeded:
            return "ファイルサイズが制限を超えています"
        case .unsupportedImageFormat:
            return "この画像形式はサポートされていません"
        case .decodingFailed:
            return "JSONのデコードに失敗しました"

        case .uploadFailed:
            return "アップロード処理中にエラーが発生しました"
        case .networkError:
            return "ネットワーク接続に問題があります"
        case .serverError:
            return "サーバー側でエラーが発生しました"
        case .timeout:
            return "アップロード処理がタイムアウトしました"
        case .insufficientStorage:
            return "サーバーの容量が不足しています"
        case .imageTooLarge:
            return "画像の解像度が制限を超えています"
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
