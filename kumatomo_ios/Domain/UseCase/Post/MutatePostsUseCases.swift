import Foundation

protocol CreatePostUseCase {
    func execute(userId: Int, content: String, tags: [String], imageData: Data?) async throws -> Post
}

protocol CreatePostWithMultipleImagesUseCase {
    func execute(userId: Int, content: String, tags: [String], imageDatas: [Data]) async throws -> Post
}

protocol UpdatePostUseCase {
    func execute(postId: Int, content: String, tags: [String]) async throws -> Post
}

protocol DeletePostUseCase {
    func execute(postId: Int) async throws
}

protocol ToggleReactionUseCase {
    func execute(postId: Int, reactionType: ReactionType) async throws -> (reactions: PostReactions, userReaction: ReactionType?)
}

final class CreatePostUseCaseImpl: CreatePostUseCase {
    private let postRepository: PostRepository
    private let imageUploadRepository: ImageUploadRepository
    init(postRepository: PostRepository, imageUploadRepository: ImageUploadRepository) {
        self.postRepository = postRepository
        self.imageUploadRepository = imageUploadRepository
    }
    func execute(userId: Int, content: String, tags: [String], imageData: Data?) async throws -> Post {
        var imageUrl: String? = nil
        if let data = imageData {
            imageUrl = try await imageUploadRepository.uploadImage(data, endpoint: "/upload-image")
        }
        return try await postRepository.createPost(userId: userId, content: content, imageUrl: imageUrl, tags: tags)
    }
}

final class CreatePostWithMultipleImagesUseCaseImpl: CreatePostWithMultipleImagesUseCase {
    private let postRepository: PostRepository
    private let imageUploadRepository: ImageUploadRepository
    init(postRepository: PostRepository, imageUploadRepository: ImageUploadRepository) {
        self.postRepository = postRepository
        self.imageUploadRepository = imageUploadRepository
    }
    func execute(userId: Int, content: String, tags: [String], imageDatas: [Data]) async throws -> Post {
        let urls = try await withThrowingTaskGroup(of: String.self) { group -> [String] in
            for data in imageDatas {
                group.addTask { try await self.imageUploadRepository.uploadImage(data, endpoint: "/upload-image") }
            }
            var results: [String] = []
            for try await u in group { results.append(u) }
            return results
        }
        return try await postRepository.createPostWithMultipleImages(userId: userId, content: content, imageUrls: urls, tags: tags)
    }
}

final class UpdatePostUseCaseImpl: UpdatePostUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(postId: Int, content: String, tags: [String]) async throws -> Post {
        try await repository.updatePost(postId: postId, content: content, tags: tags)
    }
}

final class DeletePostUseCaseImpl: DeletePostUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(postId: Int) async throws { try await repository.deletePost(postId: postId) }
}

final class ToggleReactionUseCaseImpl: ToggleReactionUseCase {
    private let repository: PostRepository
    init(repository: PostRepository) { self.repository = repository }
    func execute(postId: Int, reactionType: ReactionType) async throws -> (reactions: PostReactions, userReaction: ReactionType?) {
        try await repository.toggleReaction(postId: postId, reactionType: reactionType)
    }
}

