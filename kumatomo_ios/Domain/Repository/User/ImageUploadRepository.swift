import Foundation
import Mockable

@Mockable
protocol ImageUploadRepositoryProtocol {
    func uploadImage(_ data: Data, endpoint: String) async throws -> String

    func uploadProfileImage(_ data: Data) async throws -> String
    func uploadCoverImage(_ data: Data) async throws -> String
}
