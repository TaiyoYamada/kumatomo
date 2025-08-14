import Foundation

enum PostValidationError: LocalizedError {
    case contentEmpty
    case contentTooShort(currentCount: Int, minCount: Int)
    case contentTooLong(currentCount: Int, maxCount: Int)
    case titleEmpty
    case titleTooShort(currentCount: Int, minCount: Int)
    case titleTooLong(currentCount: Int, maxCount: Int)
    case invalidCharacters(field: String, invalidChars: [Character])
    case profanityDetected(field: String)
    case tooManyTags(currentCount: Int, maxCount: Int)
    case tagEmpty
    case tagTooLong(tagName: String, currentCount: Int, maxCount: Int)
    case duplicateTag(tagName: String)
    case invalidTagCharacters(tagName: String, invalidChars: [Character])
    case reservedTag(tagName: String)
    
    var errorDescription: String? {
        switch self {
        case .contentEmpty:
            return "投稿内容を入力してください"
        case .contentTooShort(let currentCount, let minCount):
            return "投稿内容が短すぎます (\(currentCount)/\(minCount)文字以上)"
        case .contentTooLong(let currentCount, let maxCount):
            return "投稿内容が長すぎます (\(currentCount)/\(maxCount)文字以下)"
        case .titleEmpty:
            return "タイトルを入力してください"
        case .titleTooShort(let currentCount, let minCount):
            return "タイトルが短すぎます (\(currentCount)/\(minCount)文字以上)"
        case .titleTooLong(let currentCount, let maxCount):
            return "タイトルが長すぎます (\(currentCount)/\(maxCount)文字以下)"
        case .invalidCharacters(let field, let invalidChars):
            return "\(field)に使用できない文字が含まれています: \(invalidChars.map { String($0) }.joined(separator: ", "))"
        case .profanityDetected(let field):
            return "\(field)に不適切な言葉が含まれています"
        case .tooManyTags(let currentCount, let maxCount):
            return "タグの数が多すぎます (\(currentCount)/\(maxCount)個以下)"
        case .tagEmpty:
            return "タグを入力してください"
        case .tagTooLong(let tagName, let currentCount, let maxCount):
            return "タグ「\(tagName)」が長すぎます (\(currentCount)/\(maxCount)文字以下)"
        case .duplicateTag(let tagName):
            return "タグ「\(tagName)」は既に追加されています"
        case .invalidTagCharacters(let tagName, let invalidChars):
            return "タグ「\(tagName)」に使用できない文字が含まれています: \(invalidChars.map { String($0) }.joined(separator: ", "))"
        case .reservedTag(let tagName):
            return "タグ「\(tagName)」は予約語のため使用できません"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .contentEmpty:
            return "投稿内容を入力してから投稿してください"
        case .contentTooShort:
            return "もう少し詳しく書いてみてください"
        case .contentTooLong:
            return "内容を短くまとめてください"
        case .titleEmpty:
            return "タイトルを入力してから投稿してください"
        case .titleTooShort:
            return "もう少し具体的なタイトルを入力してください"
        case .titleTooLong:
            return "タイトルを短くしてください"
        case .invalidCharacters:
            return "使用できない文字を削除してください"
        case .profanityDetected:
            return "適切な言葉に変更してください"
        case .tooManyTags:
            return "不要なタグを削除してください"
        case .tagEmpty:
            return "タグ名を入力してください"
        case .tagTooLong:
            return "タグ名を短くしてください"
        case .duplicateTag:
            return "別のタグ名を入力してください"
        case .invalidTagCharacters:
            return "タグ名から使用できない文字を削除してください"
        case .reservedTag:
            return "別のタグ名を入力してください"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .contentEmpty, .titleEmpty, .tagEmpty:
            return "必須項目が入力されていません"
        case .contentTooShort, .titleTooShort:
            return "入力内容が最小文字数を満たしていません"
        case .contentTooLong, .titleTooLong, .tagTooLong:
            return "入力内容が最大文字数を超えています"
        case .invalidCharacters, .invalidTagCharacters:
            return "使用できない文字が含まれています"
        case .profanityDetected:
            return "不適切な言葉が検出されました"
        case .tooManyTags:
            return "タグの数が制限を超えています"
        case .duplicateTag:
            return "同じタグが重複しています"
        case .reservedTag:
            return "予約語が使用されています"
        }
    }
}
