import Foundation
import SwiftUI
import Combine
import FirebaseAuth

/**
 * MemoriesViewModel - メモリー一覧画面のビューモデル
 *
 * メモリーデータの取得、追加、更新、削除などのビジネスロジックを提供します。
 * ObservableObjectに準拠しているため、SwiftUIのビューから状態変化を観測できます。
 */
class MemoriesViewModel: ObservableObject {
    /// メモリーのリスト
    @Published var memories: [Memory] = []
    
    /// 読み込み中フラグ
    @Published var isLoading: Bool = false
    
    /// エラーメッセージ
    @Published var errorMessage: String?
    
    /// 操作成功フラグ
    @Published var isSuccessful: Bool = false
    
    private let firestoreService: FirestoreService
    private let storageService: StorageService
    

    init(firestoreService: FirestoreService = FirestoreService(), storageService: StorageService = StorageService()) {
        self.firestoreService = firestoreService
        self.storageService = storageService
    }
    

    /**
     * メモリーのリストを読み込む
     */
    func loadMemories() {
        isLoading = true
        errorMessage = nil
        
        firestoreService.getMemories { [weak self] memories, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "メモリーの読み込みに失敗しました: \(error.localizedDescription)"
                    return
                }
                
                self.memories = memories ?? []
            }
        }
    }
    
    /**
     * 新しいメモリーを追加する
     *
     * - Parameters:
     *   - title: タイトル
     *   - date: 日付
     *   - location: 場所
     /Users/yamadataiyou/Developer/CoupleMate/CoupleMate/ViewModels/MemoriesViewModel.swift:76:25 Cannot find 'Auth' in scope
     *   - notes: メモ
     *   - images: 写真の配列
     *   - completion: 処理結果のコールバック
     */
    func addMemory(title: String, date: Date, location: String, notes: String, images: [UIImage], completion: @escaping (Error?) -> Void) {
        guard !title.isEmpty else {
            let error = NSError(domain: "MemoriesViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "タイトルは必須です"])
            completion(error)
            return
        }
        
        //  ここで uid を取得しておく
        guard let uid = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "MemoriesViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "ログイン情報がありません"])
            completion(error)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 画像のアップロード
        uploadImages(images) { [weak self] photoURLs, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "画像のアップロードに失敗しました: \(error.localizedDescription)"
                    completion(error)
                    return
                }
                
                // メモリーオブジェクトの作成
                let memory = Memory(
                    authorId: uid,
                    title: title,
                    date: date,
                    location: location,
                    notes: notes,
                    photos: photoURLs ?? []
                )
                
                // Firestoreに保存
                self.firestoreService.addMemory(memory) { id, error in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        if let error = error {
                            self.errorMessage = "メモリーの保存に失敗しました: \(error.localizedDescription)"
                            completion(error)
                            return
                        }
                        
                        self.isSuccessful = true
                        self.loadMemories()
                        completion(nil)
                    }
                }
            }
        }
    }
    
    /**
     * 既存のメモリーを更新する
     *
     * - Parameters:
     *   - memory: 更新対象のメモリー
     *   - newTitle: 新しいタイトル
     *   - newDate: 新しい日付
     *   - newLocation: 新しい場所
     *   - newNotes: 新しいメモ
     *   - newImages: 新しい写真の配列（nilの場合は更新しない）
     *   - completion: 処理結果のコールバック
     */
    func updateMemory(_ memory: Memory, newTitle: String, newDate: Date, newLocation: String, newNotes: String, newImages: [UIImage]? = nil, completion: @escaping (Error?) -> Void) {
        guard !newTitle.isEmpty else {
            let error = NSError(domain: "MemoriesViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "タイトルは必須です"])
            completion(error)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 新しい画像がある場合
        if let newImages = newImages, !newImages.isEmpty {
            uploadImages(newImages) { [weak self] photoURLs, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.isLoading = false
                        self.errorMessage = "画像のアップロードに失敗しました: \(error.localizedDescription)"
                        completion(error)
                        return
                    }
                    
                    // 更新するメモリーオブジェクトを作成
                    var updatedMemory = memory
                    updatedMemory.title = newTitle
                    updatedMemory.date = newDate
                    updatedMemory.location = newLocation
                    updatedMemory.notes = newNotes
                    updatedMemory.photos = photoURLs ?? []
                    updatedMemory.updatedAt = Date()
                    
                    self.updateMemoryInFirestore(updatedMemory, completion: completion)
                }
            }
        } else {
            // 画像の更新がない場合
            var updatedMemory = memory
            updatedMemory.title = newTitle
            updatedMemory.date = newDate
            updatedMemory.location = newLocation
            updatedMemory.notes = newNotes
            updatedMemory.updatedAt = Date()
            
            self.updateMemoryInFirestore(updatedMemory, completion: completion)
        }
    }
    
    /**
     * メモリーを削除する
     *
     * - Parameter indexSet: 削除する項目のインデックスセット
     */
    func deleteMemory(at indexSet: IndexSet) {
        guard let index = indexSet.first, index < memories.count else { return }
        
        let memory = memories[index]
        isLoading = true
        errorMessage = nil
        
        // Firestoreからデータを削除
        firestoreService.deleteMemory(id: memory.id) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "メモリーの削除に失敗しました: \(error.localizedDescription)"
                    return
                }
                
                // 成功したら、関連する画像も削除
                let dispatchGroup = DispatchGroup()
                
                for photoURL in memory.photos {
                    dispatchGroup.enter()
                    
                    self.storageService.deleteImage(urlString: photoURL) { _ in
                        // エラーがあっても進める（データは削除済み）
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.isLoading = false
                    self.isSuccessful = true
                    self.loadMemories()
                }
            }
        }
    }
    

    /**
     * Firestoreにメモリーを更新する内部メソッド
     */
    private func updateMemoryInFirestore(_ memory: Memory, completion: @escaping (Error?) -> Void) {
        firestoreService.updateMemory(memory) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "メモリーの更新に失敗しました: \(error.localizedDescription)"
                    completion(error)
                    return
                }
                
                self.isSuccessful = true
                self.loadMemories()
                completion(nil)
            }
        }
    }
    
    /**
     * 複数の画像をアップロードする内部メソッド
     */
    private func uploadImages(_ images: [UIImage], completion: @escaping ([String]?, Error?) -> Void) {
        guard !images.isEmpty else {
            completion([], nil)
            return
        }
        
        storageService.uploadImages(images, completion: completion)
    }
}
