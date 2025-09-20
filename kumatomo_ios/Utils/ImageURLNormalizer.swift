import Foundation

enum ImageURLNormalizer {
    /// Normalize image URL strings so they load reliably on device and simulator.
    /// - Handles relative storage paths like "/storage/..."
    /// - Rewrites localhost/127.0.0.1 hosts to match API base host
    static func normalize(_ urlString: String?) -> URL? {
        guard var raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }

        // Resolve API base origin (scheme://host[:port]) and base path
        let baseURLString = APIConfig.shared.baseURLString
        guard let baseURL = URL(string: baseURLString), var baseComps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return URL(string: raw)
        }

        // Remove trailing /api from path if present to get the real origin for assets
        if baseComps.path.hasSuffix("/api") {
            baseComps.path.removeLast(4) // remove "/api"
        }

        // Build origin string (scheme://host[:port]) optionally with base path (if any)
        var origin = ""
        if let scheme = baseComps.scheme, let host = baseComps.host {
            origin = "\(scheme)://\(host)"
            if let port = baseComps.port { origin += ":\(port)" }
            if !baseComps.path.isEmpty { origin += baseComps.path }
        }

        // If value is a relative storage path, prefix origin
        if raw.hasPrefix("/storage/") || raw.hasPrefix("storage/") {
            raw = raw.hasPrefix("/") ? raw : "/" + raw
            return URL(string: origin + raw)
        }

        // If absolute URL but localhost/127.0.0.1, rewrite to API host
        if var comps = URLComponents(string: raw), let host = comps.host, (host == "localhost" || host == "127.0.0.1") {
            comps.scheme = baseComps.scheme
            comps.host = baseComps.host
            comps.port = baseComps.port
            // keep original path/query
            return comps.url
        }

        // Otherwise return as-is
        return URL(string: raw)
    }
}

