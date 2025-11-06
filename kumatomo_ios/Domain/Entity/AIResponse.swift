import Foundation

struct AIResponse: Codable, Equatable {
    let message: String
    let timestamp: String
    let provider: String
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case message
        case timestamp
        case provider
        case success
    }

    init(message: String, timestamp: String, provider: String, success: Bool = true) {
        self.message = message
        self.timestamp = timestamp
        self.provider = provider
        self.success = success
    }
}

struct AIErrorResponse: Codable, Equatable {
    let error: Bool
    let message: String
    let code: String?
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case error
        case message
        case code
        case timestamp
    }
}