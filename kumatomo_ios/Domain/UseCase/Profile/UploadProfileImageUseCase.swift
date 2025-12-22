import Foundation
import UIKit

// MARK: - UploadProfileImageUseCase

/// プロフィール画像アップロードを行うUseCase
struct UploadProfileImageUseCase: UploadProfileImageUseCaseProtocol {

    private let imageUploadRepository: ImageUploadRepositoryProtocol

    init(imageUploadRepository: ImageUploadRepositoryProtocol) {
        self.imageUploadRepository = imageUploadRepository
    }

    func execute(image: UIImage, type: ProfileImageType) async throws -> String {
        // 画像のリサイズ
        let resizedImage = resizeImageIfNeeded(image, maxDimension: type.maxDimension)

        // 画像データに変換
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw ProfileError.imageCompressionFailed
        }

        // ファイルサイズチェック (10MB制限)
        let maxFileSizeMB = 10
        let fileSizeMB = Double(imageData.count) / (1_024 * 1_024)
        if fileSizeMB > Double(maxFileSizeMB) {
            throw ProfileError.imageTooLarge(maxSize: maxFileSizeMB)
        }

        // アップロード
        let endpoint = type == .profile ? "profile" : "cover"
        return try await imageUploadRepository.uploadImage(imageData, endpoint: endpoint)
    }

    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSize = max(size.width, size.height)

        guard maxSize > maxDimension else {
            return image
        }

        let scale = maxDimension / maxSize
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}
