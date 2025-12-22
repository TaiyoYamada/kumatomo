import Foundation

// MARK: - ToggleLikeUseCase

protocol ToggleLikeUseCase {
    func execute(postId: Int, currentState: Bool, currentCount: Int) async
        -> Result<(isLiked: Bool, likeCount: Int), EngagementError>
}

// MARK: - ToggleLikeUseCaseImpl

final class ToggleLikeUseCaseImpl: ToggleLikeUseCase {
    private let repository: EngagementRepository

    init(repository: EngagementRepository) {
        self.repository = repository
    }

    func execute(
        postId: Int,
        currentState: Bool,
        currentCount: Int
    ) async -> Result<(isLiked: Bool, likeCount: Int), EngagementError> {
        let result = await repository.optimisticToggleLike(
            postId: postId,
            currentState: currentState,
            currentCount: currentCount
        )
        if result.success, let response = result.response {
            return .success((isLiked: response.isLiked, likeCount: response.likeCount))
        } else {
            return .failure(result.error ?? .unknownError(NSError(domain: "ToggleLikeUseCase", code: -1)))
        }
    }
}
