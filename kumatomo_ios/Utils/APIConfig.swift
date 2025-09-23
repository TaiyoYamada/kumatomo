import Foundation

final class APIConfig {
    static let shared = APIConfig()

    let baseURLString: String
    let isConfigured: Bool
    var baseURL: URL? { URL(string: baseURLString) }

    private init() {
        // Prefer Info.plist (App target) then environment variable (Scheme)
        let plistURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"]

        let raw = (plistURL?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? (envURL?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }

        // Default to localhost for development if nothing set
        baseURLString = raw ?? "http://localhost:8000/api"

        // Valid if it looks like a proper HTTP(S) URL (localhost allowed)
        if let url = URL(string: baseURLString), (url.scheme == "http" || url.scheme == "https") {
            isConfigured = true
        } else {
            isConfigured = false
        }
    }
}
