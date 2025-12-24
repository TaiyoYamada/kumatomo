import Foundation

protocol AnnouncementRepositoryProtocol: Sendable {
    func fetchAnnouncements() async throws -> [Announcement]
}
