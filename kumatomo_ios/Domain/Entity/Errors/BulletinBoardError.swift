import Foundation

// MARK: - BulletinBoardError

enum BulletinBoardError: LocalizedError {
    case municipalityNotSelected
    case networkUnavailable
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .municipalityNotSelected:
            return "市町村が選択されていません"
        case .networkUnavailable:
            return "ネットワークに接続できません"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        }
    }
}
