import Alamofire
import Foundation
import UIKit

// MARK: - ImageUploadService

/// Alamofireを使用した画像アップロードサービス
class ImageUploadService: @unchecked Sendable {
    static let shared = ImageUploadService()
    private let baseURL: String = APIConfig.shared.baseURLString
    private let session: Session
    private let logger = AppLogger.network

    private init() {
        // localhost用TrustManager設定（開発用）
        let evaluators: [String: ServerTrustEvaluating] = [
            "localhost": DisabledTrustEvaluator()
        ]
        let manager = ServerTrustManager(allHostsMustBeEvaluated: false, evaluators: evaluators)
        session = Session(serverTrustManager: manager)
    }

    func uploadImage(_ image: UIImage, endpoint: String = "/upload-image") async throws -> String {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw ImageUploadError.imageConversionFailed
        }

        var headers: HTTPHeaders = []
        if let token = AuthTokenManager.shared.token {
            headers.add(.authorization(bearerToken: token))
        }

        logger.logRequest(method: "POST", url: url.absoluteString)
        logger.debug("画像データサイズ: \(imageData.count) bytes")

        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(
                        imageData,
                        withName: "image",
                        fileName: "image.jpg",
                        mimeType: "image/jpeg"
                    )
                },
                to: url,
                headers: headers
            )
            .validate(statusCode: 200 ..< 300)
            .responseDecodable(of: ImageUploadResponse.self, decoder: APIHelper.makeDecoder()) { response in

                self.logger.logResponse(
                    statusCode: response.response?.statusCode ?? -1,
                    url: url.absoluteString,
                    body: response.data.flatMap { String(data: $0, encoding: .utf8) }
                )

                switch response.result {
                case let .success(uploadResponse):
                    self.logger.info("画像アップロード成功: \(uploadResponse.url)")
                    continuation.resume(returning: uploadResponse.url)

                case let .failure(error):
                    self.logger.logError(error, context: "ImageUpload")
                    if let statusCode = response.response?.statusCode {
                        continuation.resume(throwing: ImageUploadError.uploadFailed(
                            reason: "HTTP \(statusCode): サーバーエラー"
                        ))
                    } else {
                        continuation.resume(throwing: ImageUploadError.uploadFailed(
                            reason: error.localizedDescription
                        ))
                    }
                }
            }
        }
    }

    func uploadProfileImage(_ image: UIImage) async throws -> String {
        try await uploadImage(image, endpoint: "/upload-profile-image")
    }

    func uploadCoverImage(_ image: UIImage) async throws -> String {
        try await uploadImage(image, endpoint: "/upload-cover-image")
    }
}
