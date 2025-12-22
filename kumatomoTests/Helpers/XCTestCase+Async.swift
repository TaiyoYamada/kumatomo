import XCTest

extension XCTestCase {
    /// Async/Awaitテスト用のタイムアウト付き実行ヘルパー
    func awaitAsync(
        timeout: TimeInterval = 10.0,
        file: StaticString = #file,
        line: UInt = #line,
        _ operation: @escaping () async throws -> Void
    ) {
        let expectation = expectation(description: "Async operation")

        Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed with error: \(error)", file: file, line: line)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    /// MainActor上でのasyncテスト実行ヘルパー
    @MainActor
    func awaitMainActorAsync(
        timeout _: TimeInterval = 10.0,
        file: StaticString = #file,
        line: UInt = #line,
        _ operation: @escaping @MainActor () async throws -> Void
    ) async {
        do {
            try await operation()
        } catch {
            XCTFail("MainActor async operation failed with error: \(error)", file: file, line: line)
        }
    }
}

// MARK: - Assertion Helpers

extension XCTestCase {
    /// エラーがスローされることを確認するヘルパー
    func assertThrowsAsync<T: Error>(
        _: T.Type,
        file: StaticString = #file,
        line: UInt = #line,
        _ operation: @escaping () async throws -> Void
    ) async where T: Equatable {
        do {
            try await operation()
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch {
            XCTAssertTrue(error is T, "Expected \(T.self) but got \(type(of: error))", file: file, line: line)
        }
    }

    /// エラーがスローされないことを確認するヘルパー
    func assertNoThrowAsync(
        file: StaticString = #file,
        line: UInt = #line,
        _ operation: @escaping () async throws -> Void
    ) async {
        do {
            try await operation()
        } catch {
            XCTFail("Unexpected error thrown: \(error)", file: file, line: line)
        }
    }
}
