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

    // Alternative keys to be resilient against different API shapes
    private enum AltKeys: String, CodingKey {
        case postId
        case userId
        case imageUrl
        case createdAt
        case updatedAt
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
        let alt = try? decoder.container(keyedBy: AltKeys.self)

        // Required fields with fallbacks
        id = try container.decode(Int.self, forKey: .id)
        if let value = try? container.decode(Int.self, forKey: .postId) {
            postId = value
        } else if let value = try alt?.decode(Int.self, forKey: .postId) {
            postId = value
        } else {
            throw DecodingError.keyNotFound(CodingKeys.postId, .init(codingPath: decoder.codingPath, debugDescription: "postId missing"))
        }
        if let value = try? container.decode(Int.self, forKey: .userId) {
            userId = value
        } else if let value = try alt?.decode(Int.self, forKey: .userId) {
            userId = value
        } else {
            throw DecodingError.keyNotFound(CodingKeys.userId, .init(codingPath: decoder.codingPath, debugDescription: "userId missing"))
        }
        content = (try? container.decode(String.self, forKey: .content)) ?? ""
        imageUrl = (try? container.decodeIfPresent(String.self, forKey: .imageUrl)) ?? (try? alt?.decodeIfPresent(String.self, forKey: .imageUrl)) ?? nil
        user = try container.decodeIfPresent(User.self, forKey: .user)

        // Dates: support multiple formats and keys
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)

        func parseDate(_ s: String) -> Date? {
            // With microseconds and 'Z'
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            if let d = df.date(from: s) { return d }
            // Without microseconds
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let d = df.date(from: s) { return d }
            // With timezone offset e.g. +00:00
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let d = df.date(from: s) { return d }
            // Fallback
            return nil
        }

        let createdString = (try? container.decode(String.self, forKey: .createdAt)) ?? (try? alt?.decode(String.self, forKey: .createdAt))
        createdAt = createdString.flatMap(parseDate) ?? Date()
        let updatedString = (try? container.decode(String.self, forKey: .updatedAt)) ?? (try? alt?.decode(String.self, forKey: .updatedAt))
        updatedAt = updatedString.flatMap(parseDate) ?? Date()
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
