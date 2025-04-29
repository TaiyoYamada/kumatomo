import Foundation
import Firebase
import FirebaseFirestore

/**
 * FirestoreService - Firestoreデータベースとのやり取りを行うサービスクラス
 *
 * memoriesコレクションに対するCRUD操作（作成、読み取り、更新、削除）を提供します。
 * エラーハンドリングを適切に実装し、非同期処理にはコールバックを使用しています。
 */
class FirestoreService {
    private let db = Firestore.firestore()
    private let memoriesCollection = "memories"
    
    /**
     * 全てのメモリーを取得する
     *
     * - Parameter completion: 取得結果のコールバック（メモリー配列とエラー）
     */
    func getMemories(completion: @escaping ([Memory]?, Error?) -> Void) {
        db.collection(memoriesCollection)
            .order(by: "date", descending: true)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("メモリーの取得に失敗しました: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                let memories = documents.compactMap { document -> Memory? in
                    return Memory(document: document)
                }
                
                completion(memories, nil)
            }
    }
    
    /**
     * 新しいメモリーを追加する
     *
     * - Parameters:
     *   - memory: 追加するメモリーオブジェクト
     *   - completion: 処理結果のコールバック（ドキュメントIDとエラー）
     */
    func addMemory(_ memory: Memory, completion: @escaping (String?, Error?) -> Void) {
        let ref = db.collection(memoriesCollection).document()
        let documentID = ref.documentID
        
        var memoryData = memory.toDictionary()
        
        ref.setData(memoryData) { error in
            if let error = error {
                print("メモリーの追加に失敗しました: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            completion(documentID, nil)
        }
    }
    
    /**
     * 既存のメモリーを更新する
     *
     * - Parameters:
     *   - memory: 更新するメモリーオブジェクト
     *   - completion: 処理結果のコールバック（エラー）
     */
    func updateMemory(_ memory: Memory, completion: @escaping (Error?) -> Void) {
        let memoryData = memory.toDictionary()
        
        db.collection(memoriesCollection).document(memory.id).updateData(memoryData) { error in
            if let error = error {
                print("メモリーの更新に失敗しました: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            completion(nil)
        }
    }
    
    /**
     * メモリーを削除する
     *
     * - Parameters:
     *   - id: 削除するメモリーのID
     *   - completion: 処理結果のコールバック（エラー）
     */
    func deleteMemory(id: String, completion: @escaping (Error?) -> Void) {
        db.collection(memoriesCollection).document(id).delete { error in
            if let error = error {
                print("メモリーの削除に失敗しました: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            completion(nil)
        }
    }
    
    /**
     * 単一のメモリーを取得する
     *
     * - Parameters:
     *   - id: 取得するメモリーのID
     *   - completion: 処理結果のコールバック（メモリーとエラー）
     */
    func getMemory(id: String, completion: @escaping (Memory?, Error?) -> Void) {
        db.collection(memoriesCollection).document(id).getDocument { (document, error) in
            if let error = error {
                print("メモリーの取得に失敗しました: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists else {
                let error = NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "メモリーが見つかりませんでした"])
                completion(nil, error)
                return
            }
            
            if let memory = Memory(document: document) {
                completion(memory, nil)
            } else {
                let error = NSError(domain: "FirestoreService", code: 500, userInfo: [NSLocalizedDescriptionKey: "メモリーのパースに失敗しました"])
                completion(nil, error)
            }
        }
    }
}
