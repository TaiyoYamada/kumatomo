import Foundation

// MARK: - Comment

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

    private enum AltKeys: String, CodingKey {
        case postId
        case userId
        case imageUrl
        case createdAt
        case updatedAt
    }

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
        createdAt = Date()
        updatedAt = Date()
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let alt = try? decoder.container(keyedBy: AltKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        if let value = try? container.decode(Int.self, forKey: .postId) {
            postId = value
        } else if let value = try alt?.decode(Int.self, forKey: .postId) {
            postId = value
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.postId,
                .init(codingPath: decoder.codingPath, debugDescription: "postId missing")
            )
        }
        if let value = try? container.decode(Int.self, forKey: .userId) {
            userId = value
        } else if let value = try alt?.decode(Int.self, forKey: .userId) {
            userId = value
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.userId,
                .init(codingPath: decoder.codingPath, debugDescription: "userId missing")
            )
        }
        content = (try? container.decode(String.self, forKey: .content)) ?? ""
        imageUrl = (try? container.decodeIfPresent(String.self, forKey: .imageUrl)) ?? (try? alt?.decodeIfPresent(
            String.self,
            forKey: .imageUrl
        )) ?? nil
        user = try container.decodeIfPresent(User.self, forKey: .user)

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)

        func parseDate(_ s: String) -> Date? {
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            if let d = df.date(from: s) { return d }
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let d = df.date(from: s) { return d }
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let d = df.date(from: s) { return d }
            return nil
        }

        let createdString = (try? container.decode(String.self, forKey: .createdAt)) ?? (try? alt?.decode(
            String.self,
            forKey: .createdAt
        ))
        createdAt = createdString.flatMap(parseDate) ?? Date()
        let updatedString = (try? container.decode(String.self, forKey: .updatedAt)) ?? (try? alt?.decode(
            String.self,
            forKey: .updatedAt
        ))
        updatedAt = updatedString.flatMap(parseDate) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(postId, forKey: .postId)
        try container.encode(userId, forKey: .userId)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(user, forKey: .user)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
}

extension Comment {
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var hasImage: Bool {
        return imageUrl != nil && !imageUrl!.isEmpty
    }

    var hasContent: Bool {
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func validateContent(maxLength: Int = 500) -> Bool {
        return content.count <= maxLength && hasContent
    }
}
