import Firebase
import FirebaseStorage
import UIKit

enum StoragePath {
    case profile(uid: String)
    
    var path: String {
        switch self {
        case .profile(let uid):
            return "profile_images/\(uid)"
        }
    }
}

class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage().reference()
    
    func uploadImage(_ image: UIImage, path: StoragePath) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw URLError(.badServerResponse)
        }
        
        let ref = storage.child(path.path)
        let _ = try await ref.putDataAsync(imageData)
        let url = try await ref.downloadURL()
        
        return url.absoluteString
    }
}
