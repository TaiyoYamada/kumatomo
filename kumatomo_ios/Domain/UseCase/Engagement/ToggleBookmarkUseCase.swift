import Foundation

// MARK: - ToggleBookmarkUseCase

protocol ToggleBookmarkUseCase {
    func execute(postId: Int, currentState: Bool, currentCount: Int) async -> Result<(
        isBookmarked: Bool,
        bookmarkCount: Int
    ), EngagementError>
}

// MARK: - ToggleBookmarkUseCaseImpl

final class ToggleBookmarkUseCaseImpl: ToggleBookmarkUseCase {
    private let repository: EngagementRepository

    init(repository: EngagementRepository) {
        self.repository = repository
    }

    func execute(postId: Int, currentState: Bool, currentCount: Int) async -> Result<(
        isBookmarked: Bool,
        bookmarkCount: Int
    ), EngagementError> {
        let result = await repository.optimisticToggleBookmark(
            postId: postId,
            currentState: currentState,
            currentCount: currentCount
        )
        if result.success, let response = result.response {
            return .success((isBookmarked: response.isBookmarked, bookmarkCount: response.bookmarkCount))
        } else {
            return .failure(result.error ?? .unknownError(NSError(domain: "ToggleBookmarkUseCase", code: -1)))
        }
    }
}
