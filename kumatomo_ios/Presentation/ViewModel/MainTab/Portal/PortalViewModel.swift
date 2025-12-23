import Foundation
import Observation
import Factory

@Observable
final class PortalViewModel {
    var announcements: [Announcement] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // Dependencies
    @ObservationIgnored
    private let fetchAnnouncementsUseCase: FetchAnnouncementsUseCaseProtocol
    @ObservationIgnored
    private let logger = AppLogger.debug

    init(fetchAnnouncementsUseCase: FetchAnnouncementsUseCaseProtocol = Container.shared.fetchAnnouncementsUseCase()) {
        self.fetchAnnouncementsUseCase = fetchAnnouncementsUseCase
    }

    @MainActor
    func loadAnnouncements() async {
        isLoading = true
        errorMessage = nil

        do {
            announcements = try await fetchAnnouncementsUseCase.execute()
        } catch {
            logger.logError(error, context: "FetchAnnouncements")
            errorMessage = "お知らせの取得に失敗しました"
        }

        isLoading = false
    }

    var recentAnnouncements: [Announcement] {
        // Display top 5
        Array(announcements.prefix(5))
    }
}
