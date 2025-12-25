import Foundation
import Factory

// MARK: - Domain Layer: Use Cases

extension Container {

    // MARK: - Engagement

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

    // MARK: - Search

    var searchUseCase: Factory<SearchUseCase> {
        self { SearchUseCaseImpl(repository: self.searchRepository()) }.singleton
    }

    // MARK: - Announcement

    var fetchAnnouncementsUseCase: Factory<FetchAnnouncementsUseCaseProtocol> {
        self { FetchAnnouncementsUseCase(repository: self.announcementRepository()) }.singleton
    }

    // MARK: - Post (Fetch)

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

    // MARK: - Post (Fetch with Cache)

    var fetchAllPostsWithCacheUseCase: Factory<FetchAllPostsWithCacheUseCase> {
        self { FetchAllPostsWithCacheUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var fetchMunicipalityPostsWithCacheUseCase: Factory<FetchMunicipalityPostsWithCacheUseCase> {
        self { FetchMunicipalityPostsWithCacheUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    var fetchFollowingPostsWithCacheUseCase: Factory<FetchFollowingPostsWithCacheUseCase> {
        self { FetchFollowingPostsWithCacheUseCaseImpl(repository: self.postRepository()) }.singleton
    }

    // MARK: - Post (CRUD)

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

    // MARK: - Comment

    var fetchCommentsUseCase: Factory<FetchCommentsUseCase> {
        self { FetchCommentsUseCaseImpl(repository: self.commentRepository()) }.singleton
    }

    var createCommentUseCase: Factory<CreateCommentUseCase> {
        self { CreateCommentUseCaseImpl(repository: self.commentRepository()) }.singleton
    }

    // MARK: - Auth

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

    // MARK: - Password Reset

    var sendResetCodeUseCase: Factory<SendResetCodeUseCaseProtocol> {
        self { SendResetCodeUseCase(repository: self.passwordResetRepository()) }.singleton
    }

    var verifyResetCodeUseCase: Factory<VerifyResetCodeUseCaseProtocol> {
        self { VerifyResetCodeUseCase(repository: self.passwordResetRepository()) }.singleton
    }

    var resetPasswordUseCase: Factory<ResetPasswordUseCaseProtocol> {
        self { ResetPasswordUseCase(repository: self.passwordResetRepository()) }.singleton
    }

    // MARK: - Profile

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

    // MARK: - Follow

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
