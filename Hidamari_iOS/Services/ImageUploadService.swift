import Foundation
import UIKit

// ImageUploadResponse構造体を定義
struct ImageUploadResponse: Codable {
    let url: String
}

class ImageUploadService {
    static let shared = ImageUploadService()
    private let baseURL: String = "https://localhost:8000/api"
    
    func uploadImage(_ image: UIImage, endpoint: String = "/upload-image") async throws -> String {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        // JPEG形式に変換
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw ImageUploadError.imageConversionFailed
        }
        
        // URLRequestの設定
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 認証トークンの設定 (AuthTokenManagerからトークンを取得)
        if let token = AuthTokenManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // マルチパートフォームデータを作成
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // フォームデータのボディを構築
        var body = Data()
        
        // 画像データを追加
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // フォームデータの終了
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // リクエストボディに設定
        request.httpBody = body
        
        print("🖼️ 画像アップロードを開始します: \(url)")
        print("📡 リクエストヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        print("📡 画像データサイズ: \(imageData.count) bytes")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // レスポンスのステータスコードを確認
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PostAPIError.invalidResponse
            }
            
            print("📡 ステータスコード: \(httpResponse.statusCode)")
            print("📡 レスポンスヘッダー: \(httpResponse.allHeaderFields)")
            
            // レスポンスボディを文字列として出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスボディ: \(responseString)")
            }
            
            // ステータスコードが200番台でない場合はエラー
            guard (200...299).contains(httpResponse.statusCode) else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🚨 サーバーエラーレスポンス (ステータス: \(httpResponse.statusCode)): \(responseString)")
                }
                throw ImageUploadError.uploadFailed(reason: "HTTP \(httpResponse.statusCode): サーバーエラー")
            }
            
            // JSONデコード
            do {
                let decoder = JSONDecoder()
                
                let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateStr = try container.decode(String.self)
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "無効な日付フォーマット: \(dateStr)"
                    )
                }
                
                let response = try decoder.decode(ImageUploadResponse.self, from: data)
                print("✅ 画像アップロード成功: \(response.url)")
                return response.url
            } catch {
                print("🚨 JSONデコードエラー: \(error)")
                throw ImageUploadError.decodingFailed(error)
            }
        } catch {
            print("🚨 画像アップロード失敗: \(error)")
            throw ImageUploadError.uploadFailed(reason: error.localizedDescription)
        }
    }
}

// Data拡張メソッドでマルチパートフォームデータの構築をサポート
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
