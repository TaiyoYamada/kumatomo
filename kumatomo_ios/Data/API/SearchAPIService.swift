import Foundation

class SearchAPIService {
    static let shared = SearchAPIService()

    private let baseURL = APIConfig.shared.baseURLString

    // 認証トークンの取得
    private func getAuthToken() -> String {
        return AuthTokenManager.shared.token ?? ""
    }

    // 統合検索を実行する
    func search(query: String, type: SearchFilterType = .all, page: Int = 1, perPage: Int = 10) async throws -> (SearchResult, String, SearchFilterType) {
        var urlComponents = URLComponents(string: "\(baseURL)/search")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            print("🚨 無効なURL: \(urlComponents)")
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // 認証トークンを設定
        let token = getAuthToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        print("📡 GET リクエスト: \(url.absoluteString)")
        print("📡 ヘッダー: \(request.allHTTPHeaderFields ?? [:])")

        do {
            let (data, response) = try await APISession.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            print("📡 ステータスコード: \(httpResponse.statusCode)")

            // レスポンスボディをデバッグ出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 レスポンスJSON: \(jsonString)")
            }

            if httpResponse.statusCode == 200 {
                let decoder = APIHelper.makeDecoder()

                do {
                    let apiResponse = try decoder.decode(SearchAPIResponse.self, from: data)
                    return (apiResponse.data, apiResponse.query, SearchFilterType(rawValue: apiResponse.type) ?? .all)
                } catch let decodingError as DecodingError {
                    print("🚨 デコードエラー: \(decodingError)")
                    throw APIError.decodingError(decodingError)
                } catch {
                    print("🚨 その他のデコードエラー: \(error)")
                    throw APIError.unknownError(error)
                }
            } else if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            } else if httpResponse.statusCode == 403 {
                throw APIError.forbidden
            } else if httpResponse.statusCode == 404 {
                throw APIError.notFound
            } else if httpResponse.statusCode == 429 {
                throw APIError.rateLimitExceeded
            } else if let jsonString = String(data: data, encoding: .utf8) {
                print("🚨 エラーレスポンス: \(jsonString)")
                throw APIError.apiError(statusCode: httpResponse.statusCode, message: jsonString)
            } else {
                throw APIError.serverError(message: "ステータスコード: \(httpResponse.statusCode)")
            }
        } catch let error as APIError {
            print("🚨 APIError: \(error)")
            throw error
        } catch {
            print("🚨 ネットワークエラー: \(error)")
            throw APIError.networkError(error)
        }
    }
}

private struct SearchAPIResponse: Codable {
    let data: SearchResult
    let query: String
    let type: String
}
