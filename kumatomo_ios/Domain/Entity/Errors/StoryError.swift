import Foundation

enum PostError: LocalizedError {
    case contentEmpty
    case contentOverLimit(currentCount: Int, maxCount: Int)
    case tagLimitExceeded(currentCount: Int, maxCount: Int)
    case duplicateTag(tagName: String)
    case tagEmpty
    case tagTooLong(tagName: String, currentCount: Int, maxCount: Int)
    case invalidImageData
    case submissionInProgress
    case noImagesSelected
    case tooManyImages(currentCount: Int, maxCount: Int)
    case noContentOrImages
    case noTextContent
    case noImageContent
    case noTagsSelected
    case noContent

    var errorDescription: String? {
        switch self {
        case .contentEmpty:
            return "投稿内容を入力してください"
        case let .contentOverLimit(currentCount, maxCount):
            return "文字数制限を超えています (\(currentCount)/\(maxCount)文字)"
        case let .tagLimitExceeded(currentCount, maxCount):
            return "タグの数が上限を超えています (\(currentCount)/\(maxCount)個)"
        case let .duplicateTag(tagName):
            return "タグ「\(tagName)」は既に追加されています"
        case .tagEmpty:
            return "タグを入力してください"
        case let .tagTooLong(tagName, currentCount, maxCount):
            return "タグ「\(tagName)」が長すぎます (\(currentCount)/\(maxCount)文字)"
        case .invalidImageData:
            return "画像データが無効です"
        case .submissionInProgress:
            return "投稿処理中です。しばらくお待ちください"
        case .noImagesSelected:
            return "写真を選択してください"
        case let .tooManyImages(currentCount, maxCount):
            return "写真の枚数が上限を超えています (\(currentCount)/\(maxCount)枚)"
        case .noContentOrImages:
            return "投稿するには、テキストまたは写真が必要です"
        case .noTextContent:
            return "テキストを入力してください"
        case .noImageContent:
            return "写真を選択してください"
        case .noTagsSelected:
            return "タグを最低1つ選択してください"
        case .noContent:
            return "テキストまたは画像を入力してください。"
        }
    }

    var failureReason: String? {
        switch self {
        case .contentEmpty:
            return "投稿内容が入力されていません"
        case .contentOverLimit:
            return "投稿内容が制限文字数を超えています"
        case .tagLimitExceeded:
            return "タグの数が上限を超えています"
        case .duplicateTag:
            return "同じタグが既に存在します"
        case .tagEmpty:
            return "タグが空です"
        case .tagTooLong:
            return "タグの文字数が上限を超えています"
        case .invalidImageData:
            return "画像データが無効です"
        case .submissionInProgress:
            return "投稿処理が進行中です"
        case .noImagesSelected:
            return "画像が選択されていません"
        case .tooManyImages:
            return "画像の枚数が上限を超えています"
        case .noContentOrImages:
            return "テキストまたは画像のいずれかが必要です"
        case .noTextContent:
            return "テキストが入力されていません"
        case .noImageContent:
            return "画像が選択されていません"
        case .noTagsSelected:
            return "最低1つのタグが必要です"
        case .noContent:
            return "テキストまたは画像のどちらも入力されていません"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .contentEmpty:
            return "投稿内容を入力してから投稿してください"
        case .contentOverLimit:
            return "文字数を減らしてから投稿してください"
        case .tagLimitExceeded:
            return "不要なタグを削除してから追加してください"
        case .duplicateTag:
            return "別のタグ名を入力してください"
        case .tagEmpty:
            return "タグを入力してから追加してください"
        case .tagTooLong:
            return "タグの文字数を減らしてください"
        case .invalidImageData:
            return "別の画像を選択してください"
        case .submissionInProgress:
            return "処理が完了するまでお待ちください"
        case .noImagesSelected:
            return "最低1枚の写真を選択してから投稿してください"
        case .tooManyImages:
            return "写真の枚数を減らしてから投稿してください"
        case .noContentOrImages:
            return "テキストを入力するか、写真を選択してください"
        case .noTextContent:
            return "テキストを入力してから投稿してください"
        case .noImageContent:
            return "写真を選択してから投稿してください"
        case .noTagsSelected:
            return "最低1つのタグを選択してください"
        case .noContent:
            return "テキストまたは画像を入力してから投稿してください"
        }
    }
}
