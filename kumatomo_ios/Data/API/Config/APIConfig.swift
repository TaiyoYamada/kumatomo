import Foundation

final class APIConfig {
    static let shared = APIConfig()
//    static let googlePlacesAPIKey = "AIzaSyAtd_-c8zY8W5Mi2vDaSw1CNeUcvrdEmYk"
    static let googlePlacesAPIKey = "API"

    let baseURLString: String
    let isConfigured: Bool
    var baseURL: URL? { URL(string: baseURLString) }

    private init() {
        let plistURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"]

        let raw = (plistURL?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? (envURL?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }

        baseURLString = raw ?? "http://localhost:8000/api"

        if let url = URL(string: baseURLString), url.scheme == "http" || url.scheme == "https" {
            isConfigured = true
        } else {
            isConfigured = false
        }
    }
}
