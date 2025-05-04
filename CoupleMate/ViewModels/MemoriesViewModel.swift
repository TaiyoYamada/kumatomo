import Foundation
import SwiftUI

class MemoriesViewModel: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSuccessful: Bool = false

    private let memoryAPI = MemoryAPIService.shared

    func loadMemories() {
        isLoading = true
        errorMessage = nil

        memoryAPI.fetchMemories { [weak self] memories, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "💣読み込み失敗: \(error.localizedDescription)"
                } else {
                    self?.memories = memories ?? []
                }
            }
        }
    }
    
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func addMemory(title: String, date: Date, location: String, notes: String, photos: [String], authorId: String, completion: @escaping (Error?) -> Void) {
        guard !title.isEmpty else {
            completion(NSError(domain: "MemoriesViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "タイトルは必須です"]))
            return
        }

        isLoading = true
        errorMessage = nil

        // ✅ MemoryRequest に変換して送信
        let memoryRequest = MemoryRequest(
            author_id: authorId,
            title: title,
            date: formatter.string(from: date), // ← ✅ ここ
            location: location,
            notes: notes,
            photos: photos
        )

        memoryAPI.createMemory(memoryRequest) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "保存失敗: \(error.localizedDescription)"
                    completion(error)
                    return
                }
                self?.isSuccessful = true
                self?.loadMemories()
                completion(nil)
            }
        }
    }

    func updateMemory(_ memory: Memory, newTitle: String, newDate: Date, newLocation: String, newNotes: String, newPhotos: [String]? = nil, completion: @escaping (Error?) -> Void) {
        isLoading = true
        errorMessage = nil

        var updatedMemory = memory
        updatedMemory.title = newTitle
        updatedMemory.date = newDate
        updatedMemory.location = newLocation
        updatedMemory.notes = newNotes
        updatedMemory.photos = newPhotos ?? memory.photos
        updatedMemory.updatedAt = Date()

        memoryAPI.updateMemory(updatedMemory) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "更新失敗: \(error.localizedDescription)"
                    completion(error)
                    return
                }
                self?.isSuccessful = true
                self?.loadMemories()
                completion(nil)
            }
        }
    }

    func deleteMemory(at indexSet: IndexSet) {
        guard let index = indexSet.first, index < memories.count else { return }
        let memory = memories[index]

        guard let id = memory.id else {
            errorMessage = "❌ メモリーIDが nil のため削除できません"
            return
        }

        isLoading = true
        errorMessage = nil

        memoryAPI.deleteMemory(id: String(id)) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "削除失敗: \(error.localizedDescription)"
                    return
                }
                self?.isSuccessful = true
                self?.loadMemories()
            }
        }
    }
}
