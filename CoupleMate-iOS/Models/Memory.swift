import Foundation

struct Memory: Codable, Identifiable {
    var id: Int?
    var authorId: String
    var title: String
    var date: Date
    var location: String
    var notes: String
    var photos: [String]
    var createdAt: Date
    var updatedAt: Date

    /// メイン写真（1枚目）のURLを AsyncImage 用に取得
    var mainPhotoURL: URL? {
        guard let first = photos.first else { return nil }
        return URL(string: first)
    }

    /// 新規作成用のイニシャライザ
    init(authorId: String, title: String, date: Date, location: String, notes: String, photos: [String]) {
        self.id = nil
        self.authorId = authorId
        self.title = title
        self.date = date
        self.location = location
        self.notes = notes
        self.photos = photos
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case title
        case date
        case location
        case notes
        case photos
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}


struct MemoryRequest: Codable {
    let author_id: String
    let title: String
    let date: String
    let location: String
    let notes: String
    let photos: [String]
}

