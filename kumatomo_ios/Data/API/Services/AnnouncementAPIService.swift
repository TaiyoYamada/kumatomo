import Foundation

final class AnnouncementAPIService {
    static let shared = AnnouncementAPIService()

    private let client = APIClient.shared

    private init() {}

    func fetchAnnouncements() async throws -> [AnnouncementDTO] {
        try await client.get(AnnouncementEndpoint.fetchAnnouncements)
    }
}
