import Foundation
import UIKit
import Combine

class ProfileImageManager {
    func uploadImage(_ image: UIImage) -> AnyPublisher<URL, Error> {
        // 画像をリサイズして圧縮
        guard let compressedImageData = compressImage(image) else {
            return Fail(error: ImagePickerError.compressionFailed).eraseToAnyPublisher()
        }
        
        // ここではモックとして処理を模倣
        return uploadImageToServer(compressedImageData)
    }
    
    private func compressImage(_ image: UIImage) -> Data? {
        // 画像サイズをリサイズ
        let maxSize: CGFloat = 1024
        let scale = max(maxSize / image.size.width, maxSize / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // JPEGで圧縮
        return resizedImage?.jpegData(compressionQuality: 0.7)
    }
    
    private func uploadImageToServer(_ imageData: Data) -> AnyPublisher<URL, Error> {
        // モック: 実際には適切なストレージサービスへのアップロード処理を実装
        // 成功した場合にURLを返す
        let mockURL = URL(string: "https://example.com/images/profile_\(UUID().uuidString).jpg")!
        
        return Just(mockURL)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
