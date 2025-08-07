import Foundation

struct PostImage: Identifiable, Codable {
    var id: Int
    var postId: Int
    var imageUrl: String
    var displayOrder: Int
    var createdAt: Date?
    var updatedAt: Date?
}

extension PostImage {
    init(id: Int = 0, postId: Int, imageUrl: String, displayOrder: Int = 1) {
        self.id = id
        self.postId = postId
        self.imageUrl = imageUrl
        self.displayOrder = displayOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}