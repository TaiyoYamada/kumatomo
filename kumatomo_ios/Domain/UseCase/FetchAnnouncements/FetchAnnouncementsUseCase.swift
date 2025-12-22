import Foundation

final class FetchAnnouncementsUseCase: FetchAnnouncementsUseCaseProtocol {
    private let repository: AnnouncementRepositoryProtocol

    init(repository: AnnouncementRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [Announcement] {
        return try await repository.fetchAnnouncements()
    }
}
