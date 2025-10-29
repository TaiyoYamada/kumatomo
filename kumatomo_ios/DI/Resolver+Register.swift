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
    }
}
