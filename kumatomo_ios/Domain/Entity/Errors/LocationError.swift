import Foundation

// MARK: - LocationError

enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationServicesDisabled
    case locationUnavailable
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "位置情報の使用が許可されていません。設定から許可してください。"
        case .locationServicesDisabled:
            return "位置情報サービスが無効になっています。設定から有効にしてください。"
        case .locationUnavailable:
            return "現在位置を取得できませんでした。しばらく待ってから再試行してください。"
        case .networkError:
            return "ネットワークエラーにより位置情報を取得できませんでした。"
        case .unknown:
            return "位置情報の取得中に予期しないエラーが発生しました。"
        }
    }
}
