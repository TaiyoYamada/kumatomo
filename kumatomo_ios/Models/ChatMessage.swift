import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case content
        case isFromUser = "is_from_user"
        case timestamp
    }
    
    init(content: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
    
    // Custom decoder to handle the UUID which is not encoded
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
        isFromUser = try container.decode(Bool.self, forKey: .isFromUser)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    // Custom encoder (UUID is not encoded as it's generated locally)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(isFromUser, forKey: .isFromUser)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

// MARK: - Convenience Initializers
extension ChatMessage {
    static func userMessage(_ content: String) -> ChatMessage {
        return ChatMessage(content: content, isFromUser: true)
    }
    
    static func aiMessage(_ content: String) -> ChatMessage {
        return ChatMessage(content: content, isFromUser: false)
    }
}