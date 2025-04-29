import Foundation
import FirebaseStorage
import UIKit

/**
 * StorageService - Firebase Storageへの画像アップロードを行うサービスクラス
 *
 * 画像をアップロードし、ダウンロードURLを取得する機能を提供します。
 * エラーハンドリングとプログレスモニタリングを実装しています。
 */
class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage().reference()
    private let memoriesFolder = "memories"
    
    /**
     * 画像をアップロードする
     *
     * - Parameters:
     *   - image: アップロードする画像（UIImage）
     *   - progressHandler: アップロード進捗コールバック（オプション）
     *   - completion: 処理結果のコールバック（URL文字列とエラー）
     */
    func uploadImage(_ image: UIImage, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (String?, Error?) -> Void) {
        // 画像をJPEGデータに変換
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            let error = NSError(domain: "StorageService", code: 400, userInfo: [NSLocalizedDescriptionKey: "画像データの変換に失敗しました"])
            completion(nil, error)
            return
        }
        
        // ユニークなファイル名を生成
        let filename = UUID().uuidString
        let ref = storage.child("\(memoriesFolder)/\(filename).jpg")
        
        // メタデータを設定
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // アップロードタスクを作成
        let uploadTask = ref.putData(imageData, metadata: metadata)
        
        // 進捗状況を監視
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            progressHandler?(percentComplete)
        }
        
        // タスク完了時の処理
        uploadTask.observe(.success) { _ in
            ref.downloadURL { url, error in
                if let error = error {
                    print("ダウンロードURLの取得に失敗しました: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                guard let downloadURL = url else {
                    let error = NSError(domain: "StorageService", code: 500, userInfo: [NSLocalizedDescriptionKey: "ダウンロードURLが取得できませんでした"])
                    completion(nil, error)
                    return
                }
                
                completion(downloadURL.absoluteString, nil)
            }
        }
        
        // エラー処理
        uploadTask.observe(.failure) { snapshot in
            guard let error = snapshot.error else {
                let unknownError = NSError(domain: "StorageService", code: 500, userInfo: [NSLocalizedDescriptionKey: "不明なエラーが発生しました"])
                completion(nil, unknownError)
                return
            }
            
            print("画像のアップロードに失敗しました: \(error.localizedDescription)")
            completion(nil, error)
        }
    }
    
    /**
     * 複数の画像をアップロードする
     *
     * - Parameters:
     *   - images: アップロードする画像の配列
     *   - completion: 処理結果のコールバック（URL文字列の配列とエラー）
     */
    func uploadImages(_ images: [UIImage], completion: @escaping ([String]?, Error?) -> Void) {
        guard !images.isEmpty else {
            completion([], nil)
            return
        }
        
        var uploadedURLs: [String] = []
        let dispatchGroup = DispatchGroup()
        var uploadError: Error?
        
        for image in images {
            dispatchGroup.enter()
            
            uploadImage(image) { url, error in
                if let error = error {
                    uploadError = error
                } else if let url = url {
                    uploadedURLs.append(url)
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = uploadError {
                completion(nil, error)
            } else {
                completion(uploadedURLs, nil)
            }
        }
    }
    
    /**
     * Firebase Storageから画像を削除する
     *
     * - Parameters:
     *   - urlString: 削除する画像のURL文字列
     *   - completion: 処理結果のコールバック（エラー）
     */
    func deleteImage(urlString: String, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: urlString),
              let path = url.path.components(separatedBy: "/o/").last?.removingPercentEncoding else {
            let error = NSError(domain: "StorageService", code: 400, userInfo: [NSLocalizedDescriptionKey: "不正なURL形式です"])
            completion(error)
            return
        }
        
        // パスからクエリパラメータを削除
        let imagePath = path.components(separatedBy: "?").first ?? path
        
        storage.child(imagePath).delete { error in
            if let error = error {
                print("画像の削除に失敗しました: \(error.localizedDescription)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
}

extension StorageService {
    /// 任意のパスに画像をアップロードするasyncメソッド
    func uploadImage(_ image: UIImage, path: StoragePath) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImageData
        }
        
        let ref = storage.child(path.fullPath)
        
        _ = try await ref.putDataAsync(imageData, metadata: nil)
        
        let url = try await ref.downloadURL()
        return url
    }
}


enum StoragePath {
    case profile(uid: String)
    case memory(id: String)

    var fullPath: String {
        switch self {
        case .profile(let uid):
            return "profile_images/\(uid).jpg"
        case .memory(let id):
            return "memory_images/\(id).jpg"
        }
    }
}


/// StorageService内で使うエラー
enum StorageError: LocalizedError {
    case invalidImageData
    case invalidUrl
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidImageData: return "画像データの変換に失敗しました"
        case .invalidUrl:       return "無効なURL形式です"
        case .unknown:          return "不明なエラーが発生しました"
        }
    }
}
