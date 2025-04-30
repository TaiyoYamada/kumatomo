import Foundation
import Firebase

/**
 * Memory - デート記録を表すモデルクラス
 *
 * Firestoreの「memories」コレクションのデータ構造を表します。
 * Identifiableに準拠しているため、ForEachなどでリスト表示する際にIDを自動的に使用します。
 * Codableに準拠しているため、JSONとの相互変換が容易になります。
 */
struct Memory: Identifiable, Codable {
    var authorId: String
    var id: String
    var title: String
    var date: Date
    var location: String
    var notes: String
    var photos: [String] // Firebase Storageに保存された写真のURL
    var createdAt: Date
    var updatedAt: Date
    
    /// 初期化メソッド（新規作成用）
    init(authorId: String, title: String, date: Date, location: String, notes: String, photos: [String]) {
        self.id = UUID().uuidString // 新規作成時は仮のIDを生成
        self.authorId = authorId
        self.title = title
        self.date = date
        self.location = location
        self.notes = notes
        self.photos = photos
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Firestoreドキュメントからの初期化メソッド
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        guard let title = data["title"] as? String,
              let timestamp = data["date"] as? Timestamp,
              let location = data["location"] as? String,
              let notes = data["notes"] as? String,
              let photos = data["photos"] as? [String],
              let createdTimestamp = data["createdAt"] as? Timestamp,
              let updatedTimestamp = data["updatedAt"] as? Timestamp,
              let authorId = data["authorId"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.authorId = authorId
        self.title = title
        self.date = timestamp.dateValue()
        self.location = location
        self.notes = notes
        self.photos = photos
        self.createdAt = createdTimestamp.dateValue()
        self.updatedAt = updatedTimestamp.dateValue()
    }
    
    /// Dictionaryに変換するメソッド（Firestore保存用）
    func toDictionary() -> [String: Any] {
        return [
            "authorId": authorId,
            "title": title,
            "date": Timestamp(date: date),
            "location": location,
            "notes": notes,
            "photos": photos,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    /// メイン写真のURLを取得するコンピューテッドプロパティ
    var mainPhotoURL: String? {
        return photos.first
    }
}
