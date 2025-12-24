import Foundation

struct Announcement: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let content: String
    let publishedAt: Date?
    let isActive: Bool
    let priority: Int
    let createdAt: Date
    let updatedAt: Date
}
