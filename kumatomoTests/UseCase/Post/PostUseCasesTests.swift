@testable import kumatomo
import XCTest

// MARK: - FetchAllPostsUseCaseTests

final class FetchAllPostsUseCaseTests: XCTestCase {
    var mockRepository: PostRepositoryMock!
    var sut: FetchAllPostsUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = PostRepositoryMock()
        sut = FetchAllPostsUseCaseImpl(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    func test_execute_withPaginationParams_returnsPosts() async throws {
        let expectedPosts = PostFixtures.samplePosts
        mockRepository.fetchAllPostsHandler = { _, _ in expectedPosts }

        let result = try await sut.execute(page: 1, limit: 10)

        XCTAssertEqual(result.count, expectedPosts.count)
        XCTAssertEqual(mockRepository.fetchAllPostsCallCount, 1)
    }

    func test_execute_whenRepositoryThrows_propagatesError() async {
        mockRepository.fetchAllPostsHandler = { _, _ in
            throw TestError.network
        }

        do {
            _ = try await sut.execute(page: 1, limit: 10)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }
}

// MARK: - FetchUserPostsUseCaseTests

final class FetchUserPostsUseCaseTests: XCTestCase {
    var mockRepository: PostRepositoryMock!
    var sut: FetchUserPostsUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = PostRepositoryMock()
        sut = FetchUserPostsUseCaseImpl(repository: mockRepository)
    }

    func test_execute_withUserId_fetchesUserPosts() async throws {
        let userId = 1
        let expectedPosts = [PostFixtures.createPost(userId: userId)]
        mockRepository.fetchUserPostsHandler = { _, _, _ in expectedPosts }

        let result = try await sut.execute(userId: userId, page: 1, limit: 20)

        XCTAssertEqual(result.count, expectedPosts.count)
        XCTAssertEqual(mockRepository.fetchUserPostsCallCount, 1)
    }
}

// MARK: - FetchMunicipalityPostsUseCaseTests

final class FetchMunicipalityPostsUseCaseTests: XCTestCase {
    var mockRepository: PostRepositoryMock!
    var sut: FetchMunicipalityPostsUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = PostRepositoryMock()
        sut = FetchMunicipalityPostsUseCaseImpl(repository: mockRepository)
    }

    func test_execute_withMunicipality_fetchesPosts() async throws {
        let expectedPosts = PostFixtures.samplePosts
        mockRepository.fetchMunicipalityPostsHandler = { _, _, _ in expectedPosts }

        let result = try await sut.execute(municipality: "八代市", page: 1, limit: 10)

        XCTAssertEqual(result.count, expectedPosts.count)
        XCTAssertEqual(mockRepository.fetchMunicipalityPostsCallCount, 1)
    }
}

// MARK: - FetchFollowingPostsUseCaseTests

final class FetchFollowingPostsUseCaseTests: XCTestCase {
    var mockRepository: PostRepositoryMock!
    var sut: FetchFollowingPostsUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = PostRepositoryMock()
        sut = FetchFollowingPostsUseCaseImpl(repository: mockRepository)
    }

    func test_execute_fetchesFollowingPosts() async throws {
        let expectedPosts = PostFixtures.samplePosts
        mockRepository.fetchFollowingPostsHandler = { _, _ in expectedPosts }

        let result = try await sut.execute(page: 1, limit: 10)

        XCTAssertEqual(result.count, expectedPosts.count)
        XCTAssertEqual(mockRepository.fetchFollowingPostsCallCount, 1)
    }

    func test_execute_whenNoFollowing_returnsEmptyArray() async throws {
        mockRepository.fetchFollowingPostsHandler = { _, _ in [] }

        let result = try await sut.execute(page: 1, limit: 10)

        XCTAssertTrue(result.isEmpty)
    }
}
