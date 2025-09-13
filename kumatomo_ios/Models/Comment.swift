import Foundation

struct Comment: Identifiable, Codable, Equatable {
    var id: Int
    var postId: Int
    var userId: Int
    var content: String
    var imageUrl: String?
    var createdAt: Date
    var updatedAt: Date
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
    
    // Custom initializer for creating new comments
    init(
        id: Int = 0,
        postId: Int,
        userId: Int,
        content: String,
        imageUrl: String? = nil,
        user: User? = nil
    ) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.content = content
        self.imageUrl = imageUrl
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = user
    }
    
    // Custom decoder to handle date parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        postId = try container.decode(Int.self, forKey: .postId)
        userId = try container.decode(Int.self, forKey: .userId)
        content = try container.decode(String.self, forKey: .content)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        user = try container.decodeIfPresent(User.self, forKey: .user)
        
        // Handle date parsing with multiple formats
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt) {
            if let date = dateFormatter.date(from: createdAtString) {
                createdAt = date
            } else {
                // Try alternative format without microseconds
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                createdAt = dateFormatter.date(from: createdAtString) ?? Date()
            }
        } else {
            createdAt = Date()
        }
        
        if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt) {
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            if let date = dateFormatter.date(from: updatedAtString) {
                updatedAt = date
            } else {
                // Try alternative format without microseconds
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
            }
        } else {
            updatedAt = Date()
        }
    }
    
    // Custom encoder to handle date formatting
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(postId, forKey: .postId)
        try container.encode(userId, forKey: .userId)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(user, forKey: .user)
        
        // Format dates for API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
}

// MARK: - Comment Extensions
extension Comment {
    /// Returns a formatted relative time string (e.g., "2分前", "1時間前")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// Returns true if the comment has an attached image
    var hasImage: Bool {
        return imageUrl != nil && !imageUrl!.isEmpty
    }
    
    /// Returns true if the comment content is not empty
    var hasContent: Bool {
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Validates comment content length
    func validateContent(maxLength: Int = 500) -> Bool {
        return content.count <= maxLength && hasContent
    }
}