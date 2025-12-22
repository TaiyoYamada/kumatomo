import Foundation
import UIKit

final class ImageUploadRepositoryImpl: ImageUploadRepositoryProtocol {
    private let service: ImageUploadService

    init(service: ImageUploadService = .shared) {
        self.service = service
    }

    func uploadImage(_ data: Data, endpoint: String) async throws -> String {
        guard let image = UIImage(data: data) else {
            throw ImageUploadError.imageConversionFailed
        }
        return try await service.uploadImage(image, endpoint: endpoint)
    }

    func uploadProfileImage(_ data: Data) async throws -> String {
        guard let image = UIImage(data: data) else {
            throw ImageUploadError.imageConversionFailed
        }
        return try await service.uploadProfileImage(image)
    }

    func uploadCoverImage(_ data: Data) async throws -> String {
        guard let image = UIImage(data: data) else {
            throw ImageUploadError.imageConversionFailed
        }
        return try await service.uploadCoverImage(image)
    }
}
