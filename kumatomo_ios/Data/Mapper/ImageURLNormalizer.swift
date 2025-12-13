import Foundation

enum ImageURLNormalizer {

    static func normalize(_ urlString: String?) -> URL? {
        guard var raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }

        let baseURLString = APIConfig.shared.baseURLString
        guard let baseURL = URL(string: baseURLString), var baseComps = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            return URL(string: raw)
        }

        if baseComps.path.hasSuffix("/api") {
            baseComps.path.removeLast(4)
        }

        var origin = ""
        if let scheme = baseComps.scheme, let host = baseComps.host {
            origin = "\(scheme)://\(host)"
            if let port = baseComps.port { origin += ":\(port)" }
            if !baseComps.path.isEmpty { origin += baseComps.path }
        }

        if raw.hasPrefix("/storage/") || raw.hasPrefix("storage/") {
            raw = raw.hasPrefix("/") ? raw : "/" + raw
            return URL(string: origin + raw)
        }

        if var comps = URLComponents(string: raw), let host = comps.host, host == "localhost" || host == "127.0.0.1" {
            comps.scheme = baseComps.scheme
            comps.host = baseComps.host
            comps.port = baseComps.port
            return comps.url
        }

        return URL(string: raw)
    }
}
