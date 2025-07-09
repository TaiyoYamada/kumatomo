import Foundation

enum StoryError: LocalizedError {
    case contentEmpty
    case contentOverLimit(currentCount: Int, maxCount: Int)
    case titleEmpty
    case tagLimitExceeded(currentCount: Int, maxCount: Int)
    case duplicateTag(tagName: String)
    case invalidImageData
    case submissionInProgress
    
    var errorDescription: String? {
        switch self {
        case .contentEmpty:
            return "ストーリーの内容を入力してください"
        case .contentOverLimit(let currentCount, let maxCount):
            return "文字数制限を超えています (\(currentCount)/\(maxCount)文字)"
        case .titleEmpty:
            return "タイトルを入力してください"
        case .tagLimitExceeded(let currentCount, let maxCount):
            return "タグの数が上限を超えています (\(currentCount)/\(maxCount)個)"
        case .duplicateTag(let tagName):
            return "タグ「\(tagName)」は既に追加されています"
        case .invalidImageData:
            return "画像データが無効です"
        case .submissionInProgress:
            return "投稿処理中です。しばらくお待ちください"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .contentEmpty:
            return "ストーリーの内容を入力してから投稿してください"
        case .contentOverLimit:
            return "文字数を減らしてから投稿してください"
        case .titleEmpty:
            return "タイトルを入力してから投稿してください"
        case .tagLimitExceeded:
            return "不要なタグを削除してから追加してください"
        case .duplicateTag:
            return "別のタグ名を入力してください"
        case .invalidImageData:
            return "別の画像を選択してください"
        case .submissionInProgress:
            return "処理が完了するまでお待ちください"
        }
    }
}
