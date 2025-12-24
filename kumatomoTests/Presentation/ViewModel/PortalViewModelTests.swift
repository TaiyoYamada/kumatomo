import Factory
import Foundation
@testable import kumatomo
import Mockable
import Testing

// MARK: - PortalViewModelTests

/// ポータルViewModelのテスト
@Suite("PortalViewModel Tests")
@MainActor
struct PortalViewModelTests {
    @Test("初期状態で空のお知らせリスト")
    func initialStateShouldHaveEmptyAnnouncements() async {
        // Given
        let sut = PortalViewModel()

        // Then
        #expect(sut.announcements.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("recentAnnouncementsは最大5件")
    func recentAnnouncementsShouldReturnMaxFive() async {
        // Given
        let sut = PortalViewModel()
        let now = Date()
        sut.announcements = (1 ... 10).map { index in
            Announcement(
                id: index,
                title: "お知らせ\(index)",
                content: "内容\(index)",
                publishedAt: now,
                isActive: true,
                priority: 1,
                createdAt: now,
                updatedAt: now
            )
        }

        // Then
        #expect(sut.recentAnnouncements.count == 5)
    }

    @Test("お知らせが5件以下の場合は全て返す")
    func recentAnnouncementsShouldReturnAllWhenLessThanFive() async {
        // Given
        let sut = PortalViewModel()
        let now = Date()
        sut.announcements = [
            Announcement(id: 1, title: "お知らせ1", content: "内容1", publishedAt: now, isActive: true, priority: 1, createdAt: now, updatedAt: now),
            Announcement(id: 2, title: "お知らせ2", content: "内容2", publishedAt: now, isActive: true, priority: 1, createdAt: now, updatedAt: now),
        ]

        // Then
        #expect(sut.recentAnnouncements.count == 2)
    }
}
