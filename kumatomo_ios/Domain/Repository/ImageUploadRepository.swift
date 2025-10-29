import Foundation

// Domain layer protocol for image uploads (UIKit-independent)
protocol ImageUploadRepository {
    func uploadImage(_ data: Data, endpoint: String) async throws -> String

    // Convenience helpers
    func uploadProfileImage(_ data: Data) async throws -> String
    func uploadCoverImage(_ data: Data) async throws -> String
}
