import Foundation

// MARK: - APIEndpoint

/// 型安全なAPIエンドポイント定義
protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: Any]? { get }
    var body: [String: Any]? { get }
    var requiresAuth: Bool { get }
}

// MARK: - Default Implementations

extension APIEndpoint {
    var headers: [String: String]? { nil }
    var queryParameters: [String: Any]? { nil }
    var body: [String: Any]? { nil }
    var requiresAuth: Bool { true }
}
