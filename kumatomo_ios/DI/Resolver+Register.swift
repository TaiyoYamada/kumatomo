import Foundation
import Resolver

// Centralized Resolver registrations
@MainActor
extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        // Domain -> Data adapters
        register { PostRepositoryImpl() as PostRepository }
            .scope(.application)

        register { ImageUploadRepositoryImpl() as ImageUploadRepository }
            .scope(.application)

        register { AuthRepositoryImpl() as AuthRepository }
            .scope(.application)

        register { UserRepositoryImpl() as UserRepository }
            .scope(.application)

        register { ShopRepositoryImpl() as ShopRepository }
            .scope(.application)

        register { CommentRepositoryImpl() as CommentRepository }
            .scope(.application)

        register { EngagementRepositoryImpl() as EngagementRepository }
            .scope(.application)

        register { SearchRepositoryImpl() as SearchRepository }
            .scope(.application)

        // Core utilities and services (optional direct injections)
        register { PostAPIService.shared }.scope(.application)
        register { ImageUploadService.shared }.scope(.application)
        register { EngagementAPIService.shared }.scope(.application)
        register { SearchAPIService.shared }.scope(.application)
        register { ShopAPIService.shared }.scope(.application)
        register { CommentAPIService.shared }.scope(.application)
        register { UserAPIService() }.scope(.application)
        register { AuthService.shared }.scope(.application)
        register { KumamonAIService.shared }.scope(.application)
        
        register { NetworkMonitor.shared }.scope(.application)
        register { PostCacheManager.shared }.scope(.application)
        register { FavoritesManager.shared }.scope(.application)
        register { LocationManager.shared }.scope(.application)
        register { ProfileImageManager() }.scope(.application)
        register { ProfileErrorHandler.shared }.scope(.application)

        // UseCases
        register { ToggleLikeUseCaseImpl(repository: resolve()) as ToggleLikeUseCase }
            .scope(.application)
        register { ToggleBookmarkUseCaseImpl(repository: resolve()) as ToggleBookmarkUseCase }
            .scope(.application)
        register { FetchLikedPostsUseCaseImpl(repository: resolve()) as FetchLikedPostsUseCase }
            .scope(.application)
        register { FetchBookmarkedPostsUseCaseImpl(repository: resolve()) as FetchBookmarkedPostsUseCase }
            .scope(.application)
        register { SearchUseCaseImpl(repository: resolve()) as SearchUseCase }
            .scope(.application)

        // Post UseCases
        register { FetchAllPostsUseCaseImpl(repository: resolve()) as FetchAllPostsUseCase }
            .scope(.application)
        register { FetchUserPostsUseCaseImpl(repository: resolve()) as FetchUserPostsUseCase }
            .scope(.application)
        register { FetchMunicipalityPostsUseCaseImpl(repository: resolve()) as FetchMunicipalityPostsUseCase }
            .scope(.application)
        register { FetchFollowingPostsUseCaseImpl(repository: resolve()) as FetchFollowingPostsUseCase }
            .scope(.application)
        register { FetchPostUseCaseImpl(repository: resolve()) as FetchPostUseCase }
            .scope(.application)
        register { FetchAllPostsWithCacheUseCaseImpl(repository: resolve()) as FetchAllPostsWithCacheUseCase }
            .scope(.application)
        register { FetchMunicipalityPostsWithCacheUseCaseImpl(repository: resolve()) as FetchMunicipalityPostsWithCacheUseCase }
            .scope(.application)
        register { FetchFollowingPostsWithCacheUseCaseImpl(repository: resolve()) as FetchFollowingPostsWithCacheUseCase }
            .scope(.application)
        register { CreatePostUseCaseImpl(postRepository: resolve(), imageUploadRepository: resolve()) as CreatePostUseCase }
            .scope(.application)
        register { CreatePostWithMultipleImagesUseCaseImpl(postRepository: resolve(), imageUploadRepository: resolve()) as CreatePostWithMultipleImagesUseCase }
            .scope(.application)
        register { UpdatePostUseCaseImpl(repository: resolve()) as UpdatePostUseCase }
            .scope(.application)
        register { DeletePostUseCaseImpl(repository: resolve()) as DeletePostUseCase }
            .scope(.application)
        register { ToggleReactionUseCaseImpl(repository: resolve()) as ToggleReactionUseCase }
            .scope(.application)

        // Comment UseCases
        register { FetchCommentsUseCaseImpl(repository: resolve()) as FetchCommentsUseCase }
            .scope(.application)
        register { CreateCommentUseCaseImpl(repository: resolve()) as CreateCommentUseCase }
            .scope(.application)

        // Shop UseCases
        register { FetchShopsUseCaseImpl(repository: resolve()) as FetchShopsUseCase }
            .scope(.application)
        register { FetchShopPostsUseCaseImpl(repository: resolve()) as FetchShopPostsUseCase }
            .scope(.application)

        // Auth UseCases
        register { SignInUseCaseImpl(repository: resolve()) as SignInUseCase }.scope(.application)
        register { SignOutUseCaseImpl(repository: resolve()) as SignOutUseCase }.scope(.application)
        register { CreateUserUseCaseImpl(repository: resolve()) as CreateUserUseCase }.scope(.application)
        register { UpdateUserUseCaseImpl(repository: resolve()) as UpdateUserUseCase }.scope(.application)
    }
}
