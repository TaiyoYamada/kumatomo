import Foundation

protocol FetchAnnouncementsUseCaseProtocol: Sendable {
    func execute() async throws -> [Announcement]
}
