import XCTest
import UIKit
@testable import kumatomo

/// Integration tests for CommentAPIService that test against the actual Laravel API
/// These tests require the Laravel API to be running on localhost:8000
@MainActor
class CommentAPIServiceIntegrationTests: XCTestCase {
    
    var commentAPIService: CommentAPIService!
    var testPostId: Int = 1 // Assuming there's a test post with ID 1
    
    override func setUp() {
        super.setUp()
        commentAPIService = CommentAPIService.shared
        
        // Set up test environment
        setenv("API_BASE_URL", "http://localhost:8000/api", 1)
        
        // For integration tests, we would need a valid auth token
        // In a real test environment, you would set up test authentication
        // AuthTokenManager.shared.token = "test_token_here"
    }
    
    override func tearDown() {
        commentAPIService = nil
        AuthTokenManager.shared.clearToken()
        super.tearDown()
    }
    
    // MARK: - API Endpoint Availability Tests
    
    func testAPIEndpointAvailability() async throws {
        // Test that the API base endpoint is reachable
        let url = URL(string: "http://localhost:8000/api/")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }
        
        XCTAssertEqual(httpResponse.statusCode, 200)
        
        // Parse the response to verify API is working
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["message"] as? String, "kumatomo API is working!")
    }
    
    // MARK: - Comment API Structure Tests
    
    func testCommentAPIEndpointStructure() async throws {
        // Test that comment endpoints exist (even if they return 401 due to no auth)
        let endpoints = [
            "http://localhost:8000/api/posts/1/comments",
            "http://localhost:8000/api/comments/1"
        ]
        
        for endpoint in endpoints {
            let url = URL(string: endpoint)!
            let request = URLRequest(url: url)
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    XCTFail("Invalid response type for \(endpoint)")
                    continue
                }
                
                // We expect either 401 (unauthorized) or 404 (not found) or 200 (success)
                // but not 500 (server error) which would indicate the endpoint doesn't exist
                XCTAssertTrue(
                    [200, 401, 404, 422].contains(httpResponse.statusCode),
                    "Endpoint \(endpoint) returned unexpected status: \(httpResponse.statusCode)"
                )
            } catch {
                XCTFail("Failed to reach endpoint \(endpoint): \(error)")
            }
        }
    }
    
    // MARK: - Content Validation Integration Tests
    
    func testValidateCommentContent_Integration() throws {
        // Test content validation works correctly
        XCTAssertNoThrow(try commentAPIService.validateCommentContent("Valid comment"))
        
        XCTAssertThrowsError(try commentAPIService.validateCommentContent("")) { error in
            XCTAssertTrue(error is CommentError)
            if case CommentError.emptyContent = error {
                // Expected
            } else {
                XCTFail("Expected CommentError.emptyContent")
            }
        }
        
        let longContent = String(repeating: "a", count: 501)
        XCTAssertThrowsError(try commentAPIService.validateCommentContent(longContent)) { error in
            XCTAssertTrue(error is CommentError)
            if case CommentError.contentTooLong = error {
                // Expected
            } else {
                XCTFail("Expected CommentError.contentTooLong")
            }
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testFetchComments_UnauthorizedError() async {
        // Clear auth token to test unauthorized access
        AuthTokenManager.shared.clearToken()
        
        do {
            _ = try await commentAPIService.fetchComments(postId: testPostId)
            XCTFail("Expected unauthorized error")
        } catch {
            // Should get some kind of error (likely unauthorized or network error)
            XCTAssertTrue(error is CommentError)
            print("Expected error received: \(error)")
        }
    }
    
    func testCreateComment_UnauthorizedError() async {
        // Clear auth token to test unauthorized access
        AuthTokenManager.shared.clearToken()
        
        do {
            _ = try await commentAPIService.createComment(postId: testPostId, content: "Test comment")
            XCTFail("Expected unauthorized error")
        } catch {
            // Should get some kind of error (likely unauthorized or network error)
            XCTAssertTrue(error is CommentError)
            print("Expected error received: \(error)")
        }
    }
    
    func testDeleteComment_UnauthorizedError() async {
        // Clear auth token to test unauthorized access
        AuthTokenManager.shared.clearToken()
        
        do {
            try await commentAPIService.deleteComment(commentId: 1)
            XCTFail("Expected unauthorized error")
        } catch {
            // Should get some kind of error (likely unauthorized or network error)
            XCTAssertTrue(error is CommentError)
            print("Expected error received: \(error)")
        }
    }
    
    // MARK: - URL Construction Integration Tests
    
    func testURLConstruction() {
        let baseURL = "http://localhost:8000/api"
        
        // Test fetchComments URL construction
        let fetchURL = "\(baseURL)/posts/123/comments"
        XCTAssertNotNil(URL(string: fetchURL))
        
        // Test createComment URL construction
        let createURL = "\(baseURL)/posts/456/comments"
        XCTAssertNotNil(URL(string: createURL))
        
        // Test deleteComment URL construction
        let deleteURL = "\(baseURL)/comments/789"
        XCTAssertNotNil(URL(string: deleteURL))
    }
    
    // MARK: - Service Singleton Tests
    
    func testServiceSingleton() {
        let service1 = CommentAPIService.shared
        let service2 = CommentAPIService.shared
        
        XCTAssertTrue(service1 === service2, "CommentAPIService should be a singleton")
    }
    
    // MARK: - Helper Methods Tests
    
    func testConvenienceMethods() async {
        // Test convenience methods exist and have correct signatures
        do {
            _ = try await commentAPIService.createTextComment(postId: 1, content: "Test")
            XCTFail("Expected error due to no auth")
        } catch {
            // Expected to fail due to no auth, but method should exist
            XCTAssertTrue(error is CommentError)
        }
        
        let testImage = createTestImage()
        do {
            _ = try await commentAPIService.createImageComment(postId: 1, image: testImage)
            XCTFail("Expected error due to no auth")
        } catch {
            // Expected to fail due to no auth, but method should exist
            XCTAssertTrue(error is CommentError)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}

// MARK: - Test Configuration

extension CommentAPIServiceIntegrationTests {
    
    /// Check if the Laravel API is running and accessible
    func isAPIAvailable() async -> Bool {
        do {
            let url = URL(string: "http://localhost:8000/api/")!
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
    
    /// Skip test if API is not available
    func skipIfAPINotAvailable() async throws {
        let available = await isAPIAvailable()
        if !available {
            throw XCTSkip("Laravel API is not running on localhost:8000")
        }
    }
}