//import Foundation
//import UIKit
//
//class StorageService {
//    static let shared = StorageService()
//
//    func uploadImage(_ image: UIImage, path: StoragePath) async throws -> URL {
//        // Step1: UIImage → JPEGデータに変換
//        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
//            throw StorageError.invalidImageData
//        }
//
//        // Step2: Laravel API にアップロード
//        let boundary = UUID().uuidString
//        var request = URLRequest(url: URL(string: "http://10.33.2.3/api/upload")!) // ← エンドポイント
//        request.httpMethod = "POST"
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//        var body = Data()
//
//        // 画像データをmultipart形式で追加
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(UUID().uuidString).jpg\"\r\n".data(using: .utf8)!)
//        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
//        body.append(imageData)
//        body.append("\r\n".data(using: .utf8)!)
//        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//
//        request.httpBody = body
//
//        // Step3: 実行・結果を取得
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw StorageError.unknown
//        }
//
//        // Laravel APIから返ってくる `download_url` をパース
//        let result = try JSONDecoder().decode(UploadResponse.self, from: data)
//        guard let url = URL(string: result.download_url) else {
//            throw StorageError.invalidUrl
//        }
//
//        return url
//    }
//}
//
//struct UploadResponse: Decodable {
//    let download_url: String
//}
