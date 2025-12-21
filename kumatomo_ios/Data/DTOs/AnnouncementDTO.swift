import Foundation

struct AnnouncementDTO: Codable, Sendable {
    let id: Int
    let title: String
    let content: String
    let publishedAt: String?
    let isActive: Bool
    let priority: Int
    let createdAt: String
    let updatedAt: String

    func toEntity() -> Announcement {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let publishedDate: Date? = if let dateString = publishedAt {
            formatter.date(from: dateString)
        } else {
            nil
        }

        return Announcement(
            id: id,
            title: title,
            content: content,
            publishedAt: publishedDate,
            isActive: isActive,
            priority: priority,
            createdAt: formatter.date(from: createdAt) ?? Date(),
            updatedAt: formatter.date(from: updatedAt) ?? Date()
        )
    }
}
