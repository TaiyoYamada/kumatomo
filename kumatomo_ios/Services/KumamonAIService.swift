import Foundation

class KumamonAIService {
    static let shared = KumamonAIService()
    
    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://localhost/api"
    private let timeout: TimeInterval = 30.0
    
    private init() {}
    
    // MARK: - Authentication
    private func getAuthToken() -> String {
        return AuthTokenManager.shared.token ?? ""
    }
    
    // MARK: - API Communication
    
    /// Send a message to Kumamon AI and receive a response
    /// - Parameter message: The user's message to send to the AI
    /// - Returns: AIResponse containing the AI's reply
    /// - Throws: KumamonAIError for various error conditions
    func sendMessage(_ message: String) async throws -> AIResponse {
        // Validate input
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw KumamonAIError.emptyMessage
        }
        
        let endpoint = "\(baseURL)/ai/chat"
        guard let url = URL(string: endpoint) else {
            print("🚨 無効なURL: \(endpoint)")
            throw KumamonAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        
        // Set authentication token
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ 認証トークンがありません")
            throw KumamonAIError.unauthorized
        }
        
        // Create request body
        let body = [
            "message": message
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("🚨 リクエストボディの作成エラー: \(error)")
            throw KumamonAIError.invalidMessage
        }
        
        print("📡 POST リクエスト: \(endpoint)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")
        print("📡 ボディ: \(body)")
        
        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw KumamonAIError.invalidResponse
            }
            
            print("📡 ステータスコード: \(httpResponse.statusCode)")
            
            // Debug response body
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON: \(jsonString)")
            }
            
            return try handleResponse(data: data, statusCode: httpResponse.statusCode)
            
        } catch let error as KumamonAIError {
            print("🚨 KumamonAIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            
            // Handle specific network errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw KumamonAIError.timeout
                case .notConnectedToInternet, .networkConnectionLost:
                    throw KumamonAIError.networkError(urlError)
                case .cannotFindHost, .cannotConnectToHost:
                    throw KumamonAIError.aiServiceUnavailable
                default:
                    throw KumamonAIError.networkError(urlError)
                }
            }
            
            throw KumamonAIError.unknownError(error)
        }
    }
    
    // MARK: - Response Handling
    
    private func handleResponse(data: Data, statusCode: Int) throws -> AIResponse {
        let decoder = APIHelper.makeDecoder()
        
        switch statusCode {
        case 200:
            do {
                return try decoder.decode(AIResponse.self, from: data)
            } catch {
                print("🚨 AIResponse デコードエラー: \(error)")
                throw KumamonAIError.decodingError(error as? DecodingError ?? DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unknown decoding error")))
            }
            
        case 400:
            let errorResponse = try? decoder.decode(AIErrorResponse.self, from: data)
            let message = errorResponse?.message ?? "無効なリクエストです"
            throw KumamonAIError.apiError(statusCode: 400, message: message)
            
        case 401:
            throw KumamonAIError.unauthorized
            
        case 403:
            throw KumamonAIError.forbidden
            
        case 404:
            throw KumamonAIError.notFound
            
        case 429:
            throw KumamonAIError.rateLimitExceeded
            
        case 503:
            let errorResponse = try? decoder.decode(AIErrorResponse.self, from: data)
            let message = errorResponse?.message ?? "AIサービスが利用できません"
            throw KumamonAIError.aiServiceUnavailable
            
        case 500...599:
            let errorResponse = try? decoder.decode(AIErrorResponse.self, from: data)
            let message = errorResponse?.message ?? "サーバーエラーが発生しました"
            throw KumamonAIError.serverError(message: message)
            
        default:
            let errorResponse = try? decoder.decode(AIErrorResponse.self, from: data)
            let message = errorResponse?.message ?? "予期しないエラーが発生しました"
            throw KumamonAIError.apiError(statusCode: statusCode, message: message)
        }
    }
    
    // MARK: - Health Check
    
    /// Check if the AI service is available
    /// - Returns: Boolean indicating service availability
    func checkServiceAvailability() async -> Bool {
        let endpoint = "\(baseURL)/ai/health"
        guard let url = URL(string: endpoint) else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        // Set authentication token
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (_, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            return httpResponse.statusCode == 200
        } catch {
            print("🚨 ヘルスチェックエラー: \(error)")
            return false
        }
    }
}

// MARK: - Message Validation
extension KumamonAIService {
    
    /// Validate message content before sending
    /// - Parameter message: The message to validate
    /// - Returns: Boolean indicating if the message is valid
    func isValidMessage(_ message: String) -> Bool {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty
        guard !trimmed.isEmpty else {
            return false
        }
        
        // Check length (reasonable limits)
        guard trimmed.count <= 2000 else {
            return false
        }
        
        // Check for potentially harmful content (basic validation)
        let prohibitedPatterns = ["<script", "javascript:", "data:"]
        for pattern in prohibitedPatterns {
            if trimmed.lowercased().contains(pattern) {
                return false
            }
        }
        
        return true
    }
    
    /// Sanitize message content
    /// - Parameter message: The message to sanitize
    /// - Returns: Sanitized message
    func sanitizeMessage(_ message: String) -> String {
        return message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
    }
}