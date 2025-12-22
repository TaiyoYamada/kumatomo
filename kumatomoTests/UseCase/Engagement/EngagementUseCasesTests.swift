@testable import kumatomo
import XCTest

// MARK: - ToggleLikeUseCaseTests

final class ToggleLikeUseCaseTests: XCTestCase {
    var mockRepository: EngagementRepositoryMock!
    var sut: ToggleLikeUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = EngagementRepositoryMock()
        sut = ToggleLikeUseCaseImpl(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    func test_execute_whenNotLiked_likesPost() async {
        mockRepository.optimisticToggleLikeHandler = { _, _, _ in
            (success: true, response: (isLiked: true, likeCount: 6), error: nil)
        }

        let result = await sut.execute(postId: 1, currentState: false, currentCount: 5)

        switch result {
        case let .success(value):
            XCTAssertTrue(value.isLiked)
            XCTAssertEqual(value.likeCount, 6)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_execute_whenAlreadyLiked_unlikesPost() async {
        mockRepository.optimisticToggleLikeHandler = { _, _, _ in
            (success: true, response: (isLiked: false, likeCount: 9), error: nil)
        }

        let result = await sut.execute(postId: 1, currentState: true, currentCount: 10)

        switch result {
        case let .success(value):
            XCTAssertFalse(value.isLiked)
            XCTAssertEqual(value.likeCount, 9)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_execute_whenNetworkError_returnsFailure() async {
        mockRepository.optimisticToggleLikeHandler = { _, _, _ in
            (success: false, response: nil, error: .networkError(NSError(domain: "Network", code: -1)))
        }

        let result = await sut.execute(postId: 1, currentState: false, currentCount: 5)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case let .failure(error):
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Expected network error")
            }
        }
    }

    func test_execute_whenUnauthorized_returnsUnauthorizedError() async {
        mockRepository.optimisticToggleLikeHandler = { _, _, _ in
            (success: false, response: nil, error: .unauthorized)
        }

        let result = await sut.execute(postId: 1, currentState: false, currentCount: 0)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case let .failure(error):
            if case .unauthorized = error {
                // Expected
            } else {
                XCTFail("Expected unauthorized error")
            }
        }
    }
}

// MARK: - ToggleBookmarkUseCaseTests

final class ToggleBookmarkUseCaseTests: XCTestCase {
    var mockRepository: EngagementRepositoryMock!
    var sut: ToggleBookmarkUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = EngagementRepositoryMock()
        sut = ToggleBookmarkUseCaseImpl(repository: mockRepository)
    }

    func test_execute_whenNotBookmarked_bookmarksPost() async {
        mockRepository.optimisticToggleBookmarkHandler = { _, _, _ in
            (success: true, response: (isBookmarked: true, bookmarkCount: 4), error: nil)
        }

        let result = await sut.execute(postId: 1, currentState: false, currentCount: 3)

        switch result {
        case let .success(value):
            XCTAssertTrue(value.isBookmarked)
            XCTAssertEqual(value.bookmarkCount, 4)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_execute_whenAlreadyBookmarked_unbookmarksPost() async {
        mockRepository.optimisticToggleBookmarkHandler = { _, _, _ in
            (success: true, response: (isBookmarked: false, bookmarkCount: 9), error: nil)
        }

        let result = await sut.execute(postId: 1, currentState: true, currentCount: 10)

        switch result {
        case let .success(value):
            XCTAssertFalse(value.isBookmarked)
            XCTAssertEqual(value.bookmarkCount, 9)
        case .failure:
            XCTFail("Expected success")
        }
    }
}

// MARK: - FetchLikedPostsUseCaseTests

final class FetchLikedPostsUseCaseTests: XCTestCase {
    var mockRepository: EngagementRepositoryMock!
    var sut: FetchLikedPostsUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = EngagementRepositoryMock()
        sut = FetchLikedPostsUseCaseImpl(repository: mockRepository)
    }

    func test_execute_fetchesLikedPosts() async throws {
        let expectedPosts = PostFixtures.samplePosts
        mockRepository.fetchLikedPostsHandler = { _, _ in expectedPosts }

        let result = try await sut.execute(page: 1, limit: 20)

        XCTAssertEqual(result.count, expectedPosts.count)
        XCTAssertEqual(mockRepository.fetchLikedPostsCallCount, 1)
    }
}

// MARK: - FetchBookmarkedPostsUseCaseTests

final class FetchBookmarkedPostsUseCaseTests: XCTestCase {
    var mockRepository: EngagementRepositoryMock!
    var sut: FetchBookmarkedPostsUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = EngagementRepositoryMock()
        sut = FetchBookmarkedPostsUseCaseImpl(repository: mockRepository)
    }

    func test_execute_fetchesBookmarkedPosts() async throws {
        let expectedPosts = PostFixtures.samplePosts
        mockRepository.fetchBookmarkedPostsHandler = { _, _ in expectedPosts }

        let result = try await sut.execute(page: 1, limit: 20)

        XCTAssertEqual(result.count, expectedPosts.count)
        XCTAssertEqual(mockRepository.fetchBookmarkedPostsCallCount, 1)
    }
}
