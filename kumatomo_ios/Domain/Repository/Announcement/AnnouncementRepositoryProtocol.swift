import Foundation
import Mockable

@Mockable
protocol AnnouncementRepositoryProtocol: Sendable {
    func fetchAnnouncements() async throws -> [Announcement]
}
