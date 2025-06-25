import Foundation

enum StoryAPIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    case serverError(String)
}

class StoryAPIService {
    static let shared = StoryAPIService()
    
    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8000/api"
    
    // ストーリーを投稿する
    func postStory(userId: Int, content: String) async throws -> Story {
        let endpoint = "\(baseURL)/stories"
        guard let url = URL(string: endpoint) else {
            throw StoryAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // リクエストボディの作成
        let body: [String: Any] = [
            "user_id": userId,
            "content": content
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StoryAPIError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Story.self, from: data)
            } else {
                throw StoryAPIError.serverError("ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as StoryAPIError {
            throw error
        } catch {
            throw StoryAPIError.networkError(error)
        }
    }
    
    // 全ユーザーのストーリーを取得する
    func fetchAllStories() async throws -> [Story] {
        let endpoint = "\(baseURL)/stories"
        guard let url = URL(string: endpoint) else {
            throw StoryAPIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw StoryAPIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Story].self, from: data)
        } catch let error as DecodingError {
            throw StoryAPIError.decodingError(error)
        } catch {
            throw StoryAPIError.networkError(error)
        }
    }
    
    // 特定ユーザーのストーリーを取得する
    func fetchUserStories(userId: Int) async throws -> [Story] {
        let endpoint = "\(baseURL)/users/\(userId)/stories"
        guard let url = URL(string: endpoint) else {
            throw StoryAPIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw StoryAPIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Story].self, from: data)
        } catch let error as DecodingError {
            throw StoryAPIError.decodingError(error)
        } catch {
            throw StoryAPIError.networkError(error)
        }
    }
    
    // モックデータを返す（開発用）
    func getMockStories() async -> [Story] {
        return Story.mockStories
    }
    
    // モックの投稿処理（開発用）
    func postMockStory(userId: Int, content: String) async -> Story {
        return Story(userId: userId, content: content)
    }
}
