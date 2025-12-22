import Foundation
import Factory

final class AnnouncementRepository: AnnouncementRepositoryProtocol {
    private let apiService: AnnouncementAPIService

    init(apiService: AnnouncementAPIService = Container.shared.announcementAPIService()) {
        self.apiService = apiService
    }

    func fetchAnnouncements() async throws -> [Announcement] {
        let dtos = try await apiService.fetchAnnouncements()
        return dtos.map { $0.toEntity() }
    }
}
