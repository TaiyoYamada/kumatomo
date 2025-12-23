import Foundation
import Factory

extension Container {

    // MARK: - Repositories

    var postRepository: Factory<PostRepository> {
        self { PostRepositoryImpl() }.singleton
    }

    var imageUploadRepository: Factory<ImageUploadRepositoryProtocol> {
        self { ImageUploadRepositoryImpl() }.singleton
    }

    var authRepository: Factory<AuthRepository> {
        self { AuthRepositoryImpl() }.singleton
    }

    var userRepository: Factory<UserRepositoryProtocol> {
        self { UserRepositoryImpl() }.singleton
    }

    var commentRepository: Factory<CommentRepository> {
        self { CommentRepositoryImpl() }.singleton
    }

    var engagementRepository: Factory<EngagementRepository> {
        self { EngagementRepositoryImpl() }.singleton
    }

    var searchRepository: Factory<SearchRepository> {
        self { SearchRepositoryImpl() }.singleton
    }

    var announcementRepository: Factory<AnnouncementRepositoryProtocol> {
        self { AnnouncementRepository() }.singleton
    }

    // MARK: - Services

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

    // MARK: - Use Cases (Engagement)

    var toggleLikeUseCase: Factory<ToggleLikeUseCase> {
        self { ToggleLikeUseCaseImpl(repository: self.engagementRepository()) }.singleton
    }

    var toggleBookmarkUseCase: Factory<ToggleBookmarkUseCase> {
        self { ToggleBookmarkUseCaseImpl(repository: self.engagementRepository()) }.singleton
    }

    var fetchLikedPostsUseCase: Factory<FetchLikedPostsUseCase> {
        self { FetchLikedPostsUseCaseImpl(repository: self.engagementRepository()) }.singleton
    }

    var fetchBookmarkedPostsUseCase: Factory<FetchBookmarkedPostsUseCase> {
        self { FetchBookmarkedPostsUseCaseImpl(repository: self.engagementRepository()) }.singleton
    }

    // MARK: - Use Cases (Search)

    var searchUseCase: Factory<SearchUseCase> {
        self { SearchUseCaseImpl(repository: self.searchRepository()) }.singleton
    }

    // MARK: - Use Cases (Announcement)

    var fetchAnnouncementsUseCase: Factory<FetchAnnouncementsUseCaseProtocol> {
        self { FetchAnnouncementsUseCase(repository: self.announcementRepository()) }.singleton
    }

    // MARK: - Use Cases (Post)

    var fetchAllPostsUseCase: Factory<FetchAllPostsUseCase> {
        self { FetchAllPostsUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var fetchUserPostsUseCase: Factory<FetchUserPostsUseCase> {
        self { FetchUserPostsUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var fetchMunicipalityPostsUseCase: Factory<FetchMunicipalityPostsUseCase> {
        self { FetchMunicipalityPostsUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var fetchFollowingPostsUseCase: Factory<FetchFollowingPostsUseCase> {
        self { FetchFollowingPostsUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var fetchPostUseCase: Factory<FetchPostUseCase> {
        self { FetchPostUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var fetchAllPostsWithCacheUseCase: Factory<FetchAllPostsWithCacheUseCase> {
        self { FetchAllPostsWithCacheUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var fetchMunicipalityPostsWithCacheUseCase: Factory<FetchMunicipalityPostsWithCacheUseCase> {
        self { FetchMunicipalityPostsWithCacheUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var fetchFollowingPostsWithCacheUseCase: Factory<FetchFollowingPostsWithCacheUseCase> {
        self { FetchFollowingPostsWithCacheUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var createPostUseCase: Factory<CreatePostUseCase> {
        self {
            CreatePostUseCaseImpl(
                postRepository: self.postRepository(),
                imageUploadRepository: self.imageUploadRepository()
            )
        }.singleton
    }

    var createPostWithMultipleImagesUseCase: Factory<CreatePostWithMultipleImagesUseCase> {
        self {
            CreatePostWithMultipleImagesUseCaseImpl(
                postRepository: self.postRepository(),
                imageUploadRepository: self.imageUploadRepository()
            )
        }.singleton
    }

    var updatePostUseCase: Factory<UpdatePostUseCase> {
        self { UpdatePostUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var deletePostUseCase: Factory<DeletePostUseCase> {
        self { DeletePostUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var toggleReactionUseCase: Factory<ToggleReactionUseCase> {
        self { ToggleReactionUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    // MARK: - Use Cases (Comment)

    var fetchCommentsUseCase: Factory<FetchCommentsUseCase> {
        self { FetchCommentsUseCaseImpl(repository: self.commentRepository()) }.singleton
    }

    var createCommentUseCase: Factory<CreateCommentUseCase> {
        self { CreateCommentUseCaseImpl(repository: self.commentRepository()) }.singleton
    }

    // MARK: - Use Cases (Auth/User)

    var signInUseCase: Factory<SignInUseCase> {
        self { SignInUseCaseImpl(repository: self.authRepository()) }.singleton
    }

    var signOutUseCase: Factory<SignOutUseCase> {
        self { SignOutUseCaseImpl(repository: self.authRepository()) }.singleton
    }

    var createUserUseCase: Factory<CreateUserUseCase> {
        self { CreateUserUseCaseImpl(repository: self.authRepository()) }.singleton
    }

    var updateUserUseCase: Factory<UpdateUserUseCase> {
        self { UpdateUserUseCaseImpl(repository: self.authRepository()) }.singleton
    }

    // MARK: - Use Cases (Profile)

    var validateProfileUseCase: Factory<ValidateProfileUseCaseProtocol> {
        self { ValidateProfileUseCase() }.singleton
    }

    var checkUsernameAvailabilityUseCase: Factory<CheckUsernameAvailabilityUseCaseProtocol> {
        self { CheckUsernameAvailabilityUseCase(userRepository: self.userRepository()) }.singleton
    }

    var updateProfileUseCase: Factory<UpdateProfileUseCaseProtocol> {
        self { UpdateProfileUseCase(userRepository: self.userRepository()) }.singleton
    }

    var uploadProfileImageUseCase: Factory<UploadProfileImageUseCaseProtocol> {
        self { UploadProfileImageUseCase(imageUploadRepository: self.imageUploadRepository()) }.singleton
    }

    // MARK: - Repository (Follow)

    var followRepository: Factory<FollowRepositoryProtocol> {
        self { FollowRepositoryImpl() }.singleton
    }

    // MARK: - Use Cases (Follow)

    var followUserUseCase: Factory<FollowUserUseCaseProtocol> {
        self { FollowUserUseCase(repository: self.followRepository()) }.singleton
    }

    var unfollowUserUseCase: Factory<UnfollowUserUseCaseProtocol> {
        self { UnfollowUserUseCase(repository: self.followRepository()) }.singleton
    }

    var fetchFollowersUseCase: Factory<FetchFollowersUseCaseProtocol> {
        self { FetchFollowersUseCase(repository: self.followRepository()) }.singleton
    }

    var fetchFollowingUseCase: Factory<FetchFollowingUseCaseProtocol> {
        self { FetchFollowingUseCase(repository: self.followRepository()) }.singleton
    }
}
