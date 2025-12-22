import Foundation
import UIKit

// MARK: - UploadProfileImageUseCaseProtocol

/// プロフィール画像アップロードを行うUseCaseのProtocol
protocol UploadProfileImageUseCaseProtocol: Sendable {
    /// プロフィール画像をアップロード
    /// - Parameters:
    ///   - image: アップロードする画像
    ///   - type: 画像タイプ（プロフィール or カバー）
    /// - Returns: アップロードされた画像のURL
    func execute(image: UIImage, type: ProfileImageType) async throws -> String
}

// MARK: - ProfileImageType

/// プロフィール画像のタイプ
enum ProfileImageType: Sendable {
    case profile
    case cover

    var maxDimension: CGFloat {
        switch self {
        case .profile:
            return 1_024
        case .cover:
            return 2_048
        }
    }
}
