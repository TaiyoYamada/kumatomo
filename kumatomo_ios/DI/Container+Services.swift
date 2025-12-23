import Foundation
import Factory

// MARK: - Infrastructure Layer: Services & Managers

extension Container {

    // MARK: - API Services

    var postAPIService: Factory<PostAPIService> {
        self { .shared }.singleton
    }

    var imageUploadService: Factory<ImageUploadService> {
        self { .shared }.singleton
    }

    var engagementAPIService: Factory<EngagementAPIService> {
        self { .shared }.singleton
    }

    var searchAPIService: Factory<SearchAPIService> {
        self { .shared }.singleton
    }

    var commentAPIService: Factory<CommentAPIService> {
        self { .shared }.singleton
    }

    var userAPIService: Factory<UserAPIService> {
        self { UserAPIService(client: .shared) }.singleton
    }

    var announcementAPIService: Factory<AnnouncementAPIService> {
        self { .shared }.singleton
    }

    var authService: Factory<AuthService> {
        self { .shared }.singleton
    }

    // MARK: - Infrastructure Managers

    var networkMonitor: Factory<NetworkMonitor> {
        self { .shared }.singleton
    }

    var postCacheManager: Factory<PostCacheManager> {
        self { .shared }.singleton
    }

    var locationManager: Factory<LocationManager> {
        self { .shared }.singleton
    }

    var profileImageManager: Factory<ProfileImageManager> {
        self { ProfileImageManager() }.singleton
    }

    var profileErrorHandler: Factory<ProfileErrorHandler> {
        self { MainActor.assumeIsolated { .shared } }.singleton
    }

    // MARK: - Navigation

    var appRouter: Factory<AppRouter> {
        self { MainActor.assumeIsolated { AppRouter.shared } }.singleton
    }
}
