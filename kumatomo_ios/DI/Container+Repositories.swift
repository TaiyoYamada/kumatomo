import Foundation
import Factory

// MARK: - Data Layer: Repositories

extension Container {

    // MARK: - Post

    var postRepository: Factory<PostRepository> {
        self { PostRepositoryImpl() }.singleton
    }

    // MARK: - Image

    var imageUploadRepository: Factory<ImageUploadRepositoryProtocol> {
        self { ImageUploadRepositoryImpl() }.singleton
    }

    // MARK: - Auth

    var authRepository: Factory<AuthRepository> {
        self { AuthRepositoryImpl() }.singleton
    }

    // MARK: - Password Reset

    var passwordResetRepository: Factory<PasswordResetRepository> {
        self { PasswordResetRepositoryImpl() }.singleton
    }

    // MARK: - User

    var userRepository: Factory<UserRepositoryProtocol> {
        self { UserRepositoryImpl() }.singleton
    }

    // MARK: - Comment

    var commentRepository: Factory<CommentRepository> {
        self { CommentRepositoryImpl() }.singleton
    }

    // MARK: - Engagement

    var engagementRepository: Factory<EngagementRepository> {
        self { EngagementRepositoryImpl() }.singleton
    }

    // MARK: - Search

    var searchRepository: Factory<SearchRepository> {
        self { SearchRepositoryImpl() }.singleton
    }

    // MARK: - Announcement

    var announcementRepository: Factory<AnnouncementRepositoryProtocol> {
        self { AnnouncementRepository() }.singleton
    }

    // MARK: - Follow

    var followRepository: Factory<FollowRepositoryProtocol> {
        self { FollowRepositoryImpl() }.singleton
    }
}
